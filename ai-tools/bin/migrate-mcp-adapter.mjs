#!/usr/bin/env node
import {
  closeSync,
  existsSync,
  mkdirSync,
  openSync,
  readFileSync,
  renameSync,
  statSync,
  writeFileSync,
  fsyncSync,
} from "node:fs";
import { dirname, basename, join } from "node:path";
import { randomBytes } from "node:crypto";

function usage() {
  console.error("usage: migrate-mcp-adapter.mjs <legacy-mcp-adapter-json> <target-mcp-json>");
  process.exit(64);
}

function isPlainObject(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function createJsonObject() {
  return Object.create(null);
}

function clone(value) {
  if (Array.isArray(value)) return value.map((item) => clone(item));
  if (isPlainObject(value)) {
    const result = createJsonObject();
    for (const [key, child] of Object.entries(value)) result[key] = clone(child);
    return result;
  }
  return value;
}

function normalize(value) {
  if (Array.isArray(value)) return value.map((item) => normalize(item));
  if (isPlainObject(value)) {
    const result = createJsonObject();
    for (const key of Object.keys(value).sort()) result[key] = normalize(value[key]);
    return result;
  }
  return value;
}

function sameJson(left, right) {
  return JSON.stringify(normalize(left)) === JSON.stringify(normalize(right));
}

function readOptionalJsonObject(path) {
  if (!existsSync(path)) return {};
  const text = readFileSync(path, "utf8");
  let value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    throw new Error(`invalid JSON in ${path}: ${error.message}`);
  }
  if (!isPlainObject(value)) throw new Error(`expected ${path} to contain a JSON object`);
  return value;
}

function readLegacyJsonObject(path) {
  const text = readFileSync(path, "utf8");
  try {
    const value = JSON.parse(text);
    if (!isPlainObject(value)) {
      console.error(`warning: legacy MCP adapter config ${path} is not a JSON object; no servers were migrated`);
      return null;
    }
    return value;
  } catch (error) {
    console.error(`warning: legacy MCP adapter config ${path} is invalid JSON; no servers were migrated: ${error.message}`);
    return null;
  }
}

function writeAtomic(path, text, mode) {
  const directory = dirname(path);
  mkdirSync(directory, { recursive: true });

  const temp = join(
    directory,
    `.${basename(path)}.${process.pid}.${randomBytes(6).toString("hex")}.tmp`,
  );
  const file = openSync(temp, "wx", mode);
  try {
    writeFileSync(file, text, "utf8");
    fsyncSync(file);
  } finally {
    closeSync(file);
  }

  renameSync(temp, path);
  try {
    const dir = openSync(directory, "r");
    try {
      fsyncSync(dir);
    } finally {
      closeSync(dir);
    }
  } catch (error) {
    if (error?.code !== "EINVAL" && error?.code !== "EISDIR") throw error;
  }
}

const [legacyPath, targetPath] = process.argv.slice(2);
if (!legacyPath || !targetPath) usage();

try {
  const legacy = readLegacyJsonObject(legacyPath);
  if (legacy === null) {
    console.log("was not migrated; legacy file retained as backup for manual review");
    process.exit(0);
  }

  for (const key of Object.keys(legacy).filter((key) => key !== "mcpServers")) {
    console.error(`warning: legacy MCP adapter key '${key}' is adapter-specific and was not copied to built-in mcp.json`);
  }

  if (!isPlainObject(legacy.mcpServers) || Object.keys(legacy.mcpServers).length === 0) {
    console.log("had no mcpServers to migrate");
    process.exit(0);
  }

  const existingText = existsSync(targetPath) ? readFileSync(targetPath, "utf8") : null;
  const existing = readOptionalJsonObject(targetPath);
  if (existing.mcpServers !== undefined && !isPlainObject(existing.mcpServers)) {
    throw new Error(`expected ${targetPath} mcpServers to be a JSON object`);
  }

  const next = clone(existing);
  next.mcpServers = isPlainObject(next.mcpServers) ? clone(next.mcpServers) : createJsonObject();

  let migrated = 0;
  let unchanged = 0;
  const conflicts = [];
  for (const [name, server] of Object.entries(legacy.mcpServers)) {
    if (!Object.hasOwn(next.mcpServers, name)) {
      next.mcpServers[name] = clone(server);
      migrated += 1;
    } else if (sameJson(next.mcpServers[name], server)) {
      unchanged += 1;
    } else {
      conflicts.push(name);
    }
  }

  for (const name of conflicts) {
    console.error(`warning: kept existing built-in MCP server '${name}'; differing legacy definition remains in ${legacyPath}`);
  }

  const nextText = `${JSON.stringify(next, null, 2)}\n`;
  if (existingText !== nextText) {
    const mode = existsSync(targetPath) ? statSync(targetPath).mode & 0o777 : 0o600;
    writeAtomic(targetPath, nextText, mode);
  }

  const parts = [`migrated ${migrated} MCP server(s)`];
  if (unchanged > 0) parts.push(`${unchanged} already present`);
  if (conflicts.length > 0) parts.push(`${conflicts.length} conflict(s) left in legacy backup`);
  console.log(parts.join(", "));
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
