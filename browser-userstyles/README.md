# Browser Custom Stylesheets - Monaspace Nerd Font Code View Override

This directory contains custom stylesheets (userstyles) that aggressively override default code views across websites with **Monaspace Nerd Font** (with Nerd Font icon support).

## Features

- **Aggressive Override**: Uses `!important` flags throughout to ensure late-loaded CSS doesn't take precedence
- **Resilient Design**: Multiple fallback font names and comprehensive selector coverage
- **Ligature Support**: Enables OpenType features for ligatures and stylistic sets (ss01-ss08)
- **Wide Compatibility**: Targets popular sites like GitHub, GitLab, Stack Overflow, VS Code Web, and many more
- **Nerd Font Icons**: Full support for Nerd Font icon glyphs in code views

## Prerequisites

**You must have Monaspace Nerd Font installed on your system** before using these stylesheets.

### Installing Monaspace Nerd Font

#### macOS (via Homebrew)
```bash
brew install --cask font-monaspace-nf
```

#### Linux
Download from the [Monaspace Nerd Font releases](https://github.com/githubnext/monaspace/releases) or use your package manager:
```bash
# Arch Linux
yay -S ttf-monaspace-nerd

# Manual installation
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLo "MonaspaceNeonNF.zip" https://github.com/githubnext/monaspace/releases/latest/download/monaspace-nerdfonts-v1.301.zip
unzip MonaspaceNeonNF.zip
fc-cache -fv
```

#### Windows
Download the font from [Monaspace Nerd Font releases](https://github.com/githubnext/monaspace/releases) and install it via the Fonts control panel.

## Installation Instructions

### Chrome / Edge / Brave

Chrome-based browsers require a browser extension to apply custom stylesheets.

#### Option 1: Stylus (Recommended)

1. **Install Stylus Extension**
   - Chrome: [Chrome Web Store - Stylus](https://chrome.google.com/webstore/detail/stylus/clngdbkpkpeebahjckkjfobafhncgmne)
   - Edge: [Edge Add-ons - Stylus](https://microsoftedge.microsoft.com/addons/detail/stylus/apmmpaebfobifelkijhaljbmpcgbjbdo)
   - Brave: Use Chrome Web Store link

2. **Add the Custom Style**
   - Click the Stylus extension icon
   - Click "Manage"
   - Click "Write new style"
   - Copy the entire contents of `monaspace-code-view.css` from this directory
   - Paste it into the Stylus editor
   - Name it "Monaspace Nerd Font Code View Override"
   - Save the style (Ctrl+S or Cmd+S)

3. **Verify Installation**
   - The style should be automatically enabled
   - Visit https://github.com or any site with code blocks
   - Code should now render in Monaspace Nerd Font

#### Option 2: User JavaScript and CSS Extension

1. Install [User JavaScript and CSS](https://chrome.google.com/webstore/detail/user-javascript-and-css/nbhcbdghjpllgmfilhnhkllmkecfmpld)
2. Click the extension icon
3. Add the CSS content to the "Custom CSS" section
4. Save and enable

### Firefox

Firefox has built-in support for custom stylesheets via userChrome.css, but for website styling, we recommend using Stylus.

#### Option 1: Stylus Extension (Recommended)

1. **Install Stylus**
   - Visit [Firefox Add-ons - Stylus](https://addons.mozilla.org/en-US/firefox/addon/styl-us/)
   - Click "Add to Firefox"

2. **Add the Custom Style**
   - Click the Stylus extension icon
   - Click "Manage"
   - Click "Write new style"
   - Copy the entire contents of `monaspace-code-view.css`
   - Paste it into the editor
   - Name it "Monaspace Nerd Font Code View Override"
   - Save (Ctrl+S)

3. **Ensure Style is Enabled**
   - The checkbox next to the style should be checked
   - Visit GitHub or any code-hosting site to verify

#### Option 2: userContent.css (Advanced)

For a browser-native solution without extensions:

1. **Find Your Firefox Profile Directory**
   - Navigate to `about:support` in Firefox
   - Look for "Profile Directory" and click "Open Directory"
   
2. **Create chrome Directory**
   ```bash
   # In your Firefox profile directory
   mkdir -p chrome
   ```

3. **Create userContent.css**
   - Copy `monaspace-code-view.css` to `chrome/userContent.css`
   ```bash
   cp monaspace-code-view.css chrome/userContent.css
   ```

4. **Enable userContent.css Support**
   - Navigate to `about:config` in Firefox
   - Search for `toolkit.legacyUserProfileCustomizations.stylesheets`
   - Set it to `true`

5. **Restart Firefox**

### Safari

Safari requires enabling the Developer menu and using the Web Inspector to inject stylesheets, or using a Safari extension.

#### Option 1: Userscripts Safari Extension (Recommended)

1. **Install Userscripts**
   - Search for "Userscripts" in the Mac App Store
   - Install the extension
   - Enable it in Safari Preferences → Extensions

2. **Add the Custom Style**
   - Open Userscripts from the Safari toolbar or menu bar
   - Click the "+" button to create a new userscript
   - In the editor:
     - **Name**: "Monaspace Code Font"
     - **Type**: Select "CSS" from the dropdown
     - **Run At**: "Document Start"
     - **URL Pattern**: Leave as "All Websites" or set to `*://*/*`
   - Copy the **entire contents** of `monaspace-code-view.css` (including the UserStyle metadata header)
   - Paste into the code editor area
   - Click "Save" or press Cmd+S

3. **Verify the Style is Active**
   - The userscript should appear in your Userscripts list
   - Ensure the checkbox next to it is enabled
   - Visit GitHub or any code-hosting site to test

#### Option 2: Cascadea (Paid App)

1. Purchase and install [Cascadea](https://cascadea.app) from the Mac App Store
2. Open Cascadea
3. Create a new stylesheet
4. Paste the contents of `monaspace-code-view.css`
5. Save and enable the stylesheet

#### Option 3: Safari Web Extension Development (Advanced)

For developers who want a native solution:

1. Create a Safari Web Extension using Xcode
2. Include the CSS file in the extension resources
3. Inject it using the `content_scripts` manifest key
4. Install and enable the extension

See Apple's [Safari Web Extensions documentation](https://developer.apple.com/documentation/safariservices/safari_web_extensions) for details.

## Verification

After installation, visit the following websites to verify the font is applied:

1. **GitHub**: https://github.com - View any repository file
2. **Stack Overflow**: https://stackoverflow.com - View any question with code
3. **VS Code Web**: https://vscode.dev - Open any code file
4. **GitLab**: https://gitlab.com - View any repository file
5. **CodePen**: https://codepen.io - Create or view any pen

### What to Look For

- Code blocks should render in **Monaspace Neon Nerd Font**
- Ligatures should be visible (e.g., `=>`, `!=`, `===` should render as single glyphs)
- Nerd Font icons should display correctly if present
- Font should look consistent across all code views

### Troubleshooting

If the font is not applied:

1. **Verify Font Installation**
   ```bash
   # macOS/Linux
   fc-list | grep -i monaspace
   
   # macOS specific
   system_profiler SPFontsDataType | grep -i monaspace
   ```

2. **Check Browser Console**
   - Open Developer Tools (F12)
   - Look for font-related warnings or errors
   - Verify the CSS is loaded and active

3. **Verify Extension is Active**
   - Check that Stylus (or your chosen extension) is enabled
   - Ensure the custom style is checked/enabled
   - Try refreshing the page (Ctrl+F5 / Cmd+Shift+R)

4. **Check for Conflicting Extensions**
   - Disable other extensions that might affect fonts
   - Dark mode extensions sometimes override fonts
   - Ad blockers may interfere with custom styles

5. **Browser Cache**
   - Clear browser cache and reload
   - Force reload with Ctrl+Shift+R (Cmd+Shift+R on macOS)

6. **Site-Specific Override**
   - Some sites have Content Security Policy (CSP) that may block custom fonts
   - Check browser console for CSP errors
   - The stylesheet uses local fonts only, so CSP should not be an issue

## Customization

### Using Different Monaspace Variants

The default stylesheet uses **MonaspaceNeonNF** (handwriting style). To use a different variant:

1. Open `monaspace-code-view.css` in a text editor
2. Replace all instances of `MonaspaceNeonNF` with one of:
   - `MonaspaceArgonNF` - Geometric sans (clean and modern)
   - `MonaspaceXenonNF` - Mechanical sans (technical look)
   - `MonaspaceRadonNF` - Neo-grotesque (balanced and neutral)
   - `MonaspaceKryptonNF` - Humanist sans (warm and friendly)

3. Save and reload the stylesheet in your browser

### Adjusting Font Features

To customize which OpenType features are enabled, modify the `font-feature-settings` line:

```css
font-feature-settings: "ss01" 1, "ss02" 1, "ss03" 1, "ss04" 1, 
                       "ss05" 1, "ss06" 1, "ss07" 1, "ss08" 1,
                       "calt" 1, "dlig" 1, "liga" 1 !important;
```

Available stylistic sets (ss01-ss08) provide different character variations. Set to `0` to disable a feature:

```css
font-feature-settings: "ss01" 1, "ss02" 0, "ss03" 1, /* ... */ !important;
```

### Adjusting Line Height

If you find the line height too tight or too loose:

```css
pre {
    line-height: 1.5 !important;  /* Adjust this value (1.2 - 1.8) */
}
```

## Technical Details

### Why This Approach Works

1. **Aggressive !important Usage**: Every rule uses `!important` to override any existing styles, including late-loaded CSS from CDNs

2. **Multiple Selectors**: The stylesheet targets:
   - Standard HTML elements (`code`, `pre`, `kbd`, `samp`, `tt`, `var`)
   - Common CSS class names (`.code`, `.highlight`, `.hljs`, etc.)
   - Site-specific selectors (GitHub, GitLab, VS Code, etc.)
   - Editor components (Monaco, CodeMirror, Ace)
   - Inline style attributes

3. **Font Fallback Chain**: Provides multiple fallback options to ensure the font loads even if the exact name varies

4. **Recursive Inheritance**: Uses `inherit !important` on child elements to propagate font settings

5. **OpenType Features**: Explicitly enables ligatures and stylistic sets that make code more readable

### Performance Impact

The stylesheet has minimal performance impact because:
- It only affects text rendering, not layout
- Uses CSS native features (no JavaScript)
- Font features are hardware-accelerated on modern browsers
- Selector specificity is kept reasonable despite aggressive matching

## Contributing

If you find a site where the stylesheet doesn't work, please:

1. Identify the CSS selectors used for code blocks on that site
2. Add them to `monaspace-code-view.css` in the appropriate section
3. Test thoroughly
4. Submit a pull request to the [dotfiles repository](https://github.com/djensenius/dotfiles)

## License

MIT License - See the [LICENSE](../LICENSE) file in the repository root.

## Related Projects

- [Monaspace](https://github.com/githubnext/monaspace) - The original Monaspace font family
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) - Iconic font aggregator and patcher
- [Stylus](https://github.com/openstyles/stylus) - User styles manager for all browsers

## Credits

- Font: [Monaspace](https://monaspace.githubnext.com) by GitHub Next
- Nerd Font patches: [Nerd Fonts project](https://www.nerdfonts.com)
- Stylesheet author: David Jensenius
- Repository: [djensenius/dotfiles](https://github.com/djensenius/dotfiles)
