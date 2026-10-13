#!/usr/bin/env node
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, renameSync, statSync, writeFileSync, fsyncSync } from "node:fs";
import { dirname, basename, join } from "node:path";
import { randomBytes } from "node:crypto";

function usage() {
  console.error("usage: merge-json.mjs <target-json> <source-json> [source-json ...]");
  process.exit(64);
}

const missingDefault = Symbol("missing-default");

function readJsonObject(path, missingValue = missingDefault) {
  if (!existsSync(path)) {
    if (missingValue !== missingDefault) return missingValue;
    throw new Error(`missing JSON source ${path}`);
  }

  const text = readFileSync(path, "utf8");
  let value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    throw new Error(`invalid JSON in ${path}: ${error.message}`);
  }
  if (!isPlainObject(value)) {
    throw new Error(`expected ${path} to contain a JSON object`);
  }
  return value;
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

function deepMerge(base, overlay) {
  const result = clone(base);
  for (const [key, overlayValue] of Object.entries(overlay)) {
    const baseValue = result[key];
    result[key] = isPlainObject(baseValue) && isPlainObject(overlayValue)
      ? deepMerge(baseValue, overlayValue)
      : clone(overlayValue);
  }
  return result;
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

const [target, ...sources] = process.argv.slice(2);
if (!target || sources.length === 0) usage();

try {
  const existingText = existsSync(target) ? readFileSync(target, "utf8") : null;
  const existing = readJsonObject(target, {});
  const merged = sources
    .map((source) => readJsonObject(source, undefined))
    .reduce((result, source) => deepMerge(result, source), existing);
  const nextText = `${JSON.stringify(merged, null, 2)}\n`;
  if (existingText === nextText) {
    console.log("is up to date");
    process.exit(0);
  }

  const mode = existsSync(target) ? statSync(target).mode & 0o777 : 0o600;
  writeAtomic(target, nextText, mode);
  console.log(existingText === null ? "created" : "updated");
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
