---
name: cli-distribution
description: >
  Patterns for distributing Python CLI tools — tab completion, man pages,
  help text, and Homebrew formula setup. Load when building or extending a
  CLI that will be distributed via Homebrew, or when adding shell completion,
  man pages, -h/--help flags, or the alph completions show/install commands.
  Covers Typer-specific gotchas learned from the alph project.
---

# CLI Distribution Patterns

Covers the surface area users touch outside the code itself: shell completion,
help text, man pages, and packaging via Homebrew. All of these interact in
non-obvious ways; the gotchas section is as important as the patterns.

---

## Help Text (`-h` / `--help`)

Typer exposes `--help` by default. Add `-h` as an alias via `context_settings`:

```python
_help_settings = {"help_option_names": ["-h", "--help"]}
app = typer.Typer(context_settings=_help_settings)
```

Apply the same `context_settings` to every sub-Typer (registry_app, pool_app,
etc.) so `-h` works at every level, not just the root command.

```python
registry_app = typer.Typer(
    help="Registry commands.",
    invoke_without_command=True,
    context_settings=_help_settings,
)
```

---

## Man Pages

Write a `man/alph.1` roff file. Homebrew installs it via `man1.install` in the
formula. Users then run `man alph`.

**Formula line:**
```ruby
man1.install "man/alph.1"
```

**What the man page must cover:**
- All commands and subcommands with their flags
- All config file keys (users frequently miss these — they exist nowhere else)
- A concrete YAML config example
- Environment variables
- Examples section with real invocations
- Tab completion section (where to find the script, how to activate it)

**Version string:** Update the `.TH` header on every release:
```
.TH ALPH 1 "2026-03-16" "alph 0.1.36" "Alpheus Context Engine Framework"
```

---

## Tab Completion

### How Typer completion works (and how it breaks)

Typer has **two separate completion mechanisms** that must both work:

1. **Script generation** (`_ALPH_COMPLETE=source_zsh alph`): produces the
   static completion script written to the shell's `fpath` directory.
2. **Runtime completion** (`_ALPH_COMPLETE=complete_zsh alph`): called by the
   installed script on every tab press to return live completions.

**Critical**: `add_completion=False` on the `typer.Typer(...)` constructor
prevents `completion_init()` from ever being called. Without it, Typer's
`ZshComplete` override is never registered, and script generation falls back to
Click's built-in template. Click's template uses `COMP_WORDS`/`zsh_complete`
format; Typer's runtime handler expects `_TYPER_COMPLETE_ARGS`/`complete_zsh`.
The mismatch makes every tab press silently return nothing and fall back to
file listing.

**Rule: always leave `add_completion` at its default (`True`).**

### Leading-newline bug in Typer's zsh script

Typer's `source_zsh` output starts with `\n#compdef alph` instead of
`#compdef alph`. zsh's `compinit` requires `#compdef` at byte offset 0 of the
file — a leading newline causes compinit to skip the file entirely, so the
completion function is never registered. Tab presses silently fall back to
filesystem listing with no error.

**Fix:** Strip leading whitespace from the generated script before writing it —
both in the Homebrew formula and in any `completions install` command:

```python
# In _generate_completion_script:
return result.stdout.lstrip("\n")
```

```ruby
# In the Homebrew formula:
(zsh_completion/"_alph").write \
  Utils.safe_popen_read({ "_ALPH_COMPLETE" => "source_zsh" }, bin/"alph").lstrip
```

### Why `--install-completion` fails in some environments

Typer's built-in `--install-completion` uses `shellingham` to detect the
current shell. `shellingham.detect_shell()` fails under pyenv shims,
non-interactive contexts, and some tmux setups, returning `None` →
"Shell None is not supported."

**Solution:** Implement `alph completions show/install` as explicit commands
using the `_ALPH_COMPLETE=source_<shell>` env var mechanism with `$SHELL`
basename fallback. Do NOT set `add_completion=False` to suppress the broken
built-in — that breaks the runtime completion mechanism (see above).

```python
completions_app = typer.Typer(help="Shell tab completion commands.", ...)
app.add_typer(completions_app, name="completions")

def _generate_completion_script(shell: str) -> str:
    env = {**os.environ, "_ALPH_COMPLETE": f"source_{shell}"}
    result = subprocess.run(["alph"], env=env, capture_output=True, text=True)
    # Typer emits a leading newline before #compdef — strip it so
    # compinit recognises the file (#compdef must be on byte 0).
    return result.stdout.lstrip("\n")

def _resolve_shell(shell: str | None) -> str:
    if shell:
        return shell.lower()
    shell_env = os.environ.get("SHELL", "")
    if shell_env:
        return Path(shell_env).name.lower()
    raise typer.BadParameter("Could not detect shell. Pass: zsh, bash, or fish.")
```

### Wiring completions to arguments

```python
@registry_app.command("check")
def registry_check(
    registry: str = typer.Argument(
        None,
        autocompletion=_complete_registry_id,
    ),
):
    ...
```

`autocompletion=` on `typer.Argument` and `typer.Option` is how custom
completion functions attach. The function receives `(ctx, param, incomplete)`
and returns a list of strings (or `(value, description)` tuples).

```python
def _complete_registry_id(ctx, param, incomplete: str) -> list[str]:
    try:
        cfg = _load_cli_config()
        ids = [r.registry_id for r in collect_registries(cfg=cfg)]
        ids.append("all")
        return [i for i in ids if i.startswith(incomplete)]
    except Exception:
        return []
```

Always swallow exceptions in completion functions — a crash during tab
completion produces a confusing error and breaks the shell session.

### Homebrew formula: generating completions at install time

Typer exposes the completion script via `_ALPH_COMPLETE=source_<shell>`. Use
`Utils.safe_popen_read` in the formula `install` block:

```ruby
(zsh_completion/"_alph").write \
  Utils.safe_popen_read({ "_ALPH_COMPLETE" => "source_zsh" }, bin/"alph")
(bash_completion/"alph").write \
  Utils.safe_popen_read({ "_ALPH_COMPLETE" => "source_bash" }, bin/"alph")
(fish_completion/"alph.fish").write \
  Utils.safe_popen_read({ "_ALPH_COMPLETE" => "source_fish" }, bin/"alph")
```

This runs after the binary is installed, so the script is always generated
from the actual installed version.

### Homebrew formula: caveats for shell setup

Homebrew installs the completion file but does not modify `~/.zshrc`. Users
must add `HOMEBREW_PREFIX/share/zsh/site-functions` to their `fpath` manually.
The formula `caveats` block is the only place to tell them this.

**Oh My Zsh gotcha:** OMZ runs its own `compinit` inside `source $ZSH/oh-my-zsh.sh`.
Any `fpath` additions that appear after that line are too late — `compinit` has
already finished and won't rescan. The `fpath` line must appear **before** the
`source $ZSH/oh-my-zsh.sh` call, not at the end of `~/.zshrc` where most users
would naturally put it. This also means `autoload -Uz compinit && compinit`
should be omitted — OMZ handles it. Adding a second `compinit` call after OMZ
has run is harmless but redundant; it will use the (already correct) cache.

**Stale compinit cache:** `compinit` writes a cache file (`~/.zcompdump*`). If
the cache was built before `_alph` appeared in `fpath`, the function will not be
loaded even after the `fpath` is fixed. Delete all variants to force a rescan:
```zsh
rm -f ~/.zcompdump* && exec zsh
```

```ruby
def caveats
  <<~EOS
    Tab completion has been installed for zsh, bash, and fish.

    zsh: add the following to ~/.zshrc if not already present:
      fpath=(#{HOMEBREW_PREFIX}/share/zsh/site-functions $fpath)
      autoload -Uz compinit && compinit

    bash: add the following to ~/.bashrc if not already present:
      [[ -r "#{HOMEBREW_PREFIX}/etc/bash_completion.d/alph" ]] && \\
        source "#{HOMEBREW_PREFIX}/etc/bash_completion.d/alph"

    fish: completions are loaded automatically — no setup needed.

    Reload your shell (exec zsh / exec bash) after editing your rc file.
  EOS
end
```

Use `#{HOMEBREW_PREFIX}` (Ruby interpolation), not a hardcoded path — it
resolves to `/opt/homebrew` on Apple Silicon and `/usr/local` on Intel.

### Testing the completion pipeline end-to-end

```bash
# 1. Verify script generation produces Typer's format (not Click's)
_ALPH_COMPLETE=source_zsh alph | grep "COMPLETE\|TYPER"
# Expected: _ALPH_COMPLETE=complete_zsh (not COMP_WORDS/zsh_complete)

# 2. Verify runtime completion returns results
_TYPER_COMPLETE_ARGS="alph registry check " _ALPH_COMPLETE=complete_zsh alph
# Expected: list of registry IDs

# 3. Verify installed script uses correct format
grep "COMPLETE\|TYPER" /opt/homebrew/share/zsh/site-functions/_alph
# Expected: _ALPH_COMPLETE=complete_zsh

# 4. Verify fpath includes Homebrew completions dir
echo $fpath | tr ' ' '\n' | grep homebrew
# Expected: /opt/homebrew/share/zsh/site-functions
```

If step 1 shows `COMP_WORDS`/`zsh_complete` instead of `_TYPER_COMPLETE_ARGS`/
`complete_zsh`, `completion_init()` was never called — check `add_completion`.

---

## Homebrew Formula: Versioning and SHA

### Why GitHub auto-generated tarballs break Homebrew

GitHub's `/archive/refs/tags/vX.Y.Z.tar.gz` endpoint generates tarballs
on-the-fly and caches them across CDN nodes. After a new tag is created, the
tarball may not be cached yet or may be re-generated with different gzip
metadata, producing a different SHA256 on each download. This is
non-deterministic and can persist for minutes after a release is created.
Brew's download may hit a different CDN node than `curl` did, so even a
verified `curl | shasum` value can mismatch at install time.

### Preferred approach: upload a release asset

Generate a deterministic tarball locally with `git archive` and upload it as a
release asset. Release assets are stored as static blobs — their SHA never
changes.

```bash
# 1. Tag and push
git tag v0.2.0 && git push origin v0.2.0

# 2. Create the release
gh release create v0.2.0 --title "v0.2.0" --notes "Release notes here."

# 3. Build a deterministic tarball (prefix must match what brew expects)
git archive --format=tar.gz --prefix=my-tool-0.2.0/ v0.2.0 \
  -o my-tool-0.2.0.tar.gz

# 4. Upload as a release asset
gh release upload v0.2.0 my-tool-0.2.0.tar.gz

# 5. Get the SHA (verify it's stable — run twice)
curl -sL https://github.com/USER/REPO/releases/download/v0.2.0/my-tool-0.2.0.tar.gz \
  | shasum -a 256

# 6. Use the release asset URL in the formula (not /archive/refs/tags/)
url "https://github.com/USER/REPO/releases/download/v0.2.0/my-tool-0.2.0.tar.gz"
sha256 "<the stable hash>"
```

### Fallback: brew fetch --force

If you must use auto-generated archives (e.g. for an existing formula), use
`brew fetch --force` instead of `curl | shasum`:

```bash
brew fetch --force Formula/my-tool.rb
# Read the SHA from the output and paste into sha256
```

If the SHA still mismatches at install time, `brew install` prints the correct
SHA in its error message — use that value. But this is a symptom of the
non-deterministic archive problem; prefer the release-asset approach above.

### Brew cache and stale formulas

After updating a formula's SHA or URL, brew may still use a stale cached copy
of the formula or tarball:

```bash
# Force-refresh the tap (pulls latest formula definitions)
cd $(brew --repository USER/tap) && git pull

# Clear cached downloads for the formula
rm -f ~/Library/Caches/Homebrew/downloads/*my-tool*

# Then install/reinstall
brew reinstall USER/tap/my-tool
```

`brew tap --force USER/tap` and `brew update` do not always pick up changes
immediately if the tap was recently fetched. The `cd && git pull` approach is
reliable.

### Version bump checklist

- `pyproject.toml` version
- `man/*.1` `.TH` header version string (if applicable)
- Git tag matching the version (`git tag vX.Y.Z && git push origin vX.Y.Z`)
- `git archive` + `gh release upload` to create a stable tarball
- Homebrew formula `url` (release asset URL) and `sha256`
- `STATE.md` current version line (if applicable)

---

## Shorthand Subcommands

Typer lets you register the same `Typer` instance under multiple names:

```python
app.add_typer(registry_app, name="registry")
app.add_typer(registry_app, name="reg", hidden=True)  # shorthand
```

`hidden=True` suppresses `reg` from `--help` output while keeping it
functional. Tab completion still completes `reg` subcommands because it's the
same underlying object.

For commands where `alph registry` with no subcommand should default to
`alph registry list`, use `invoke_without_command=True` and check in the
callback:

```python
registry_app = typer.Typer(invoke_without_command=True, ...)

@registry_app.callback()
def registry_callback(ctx: typer.Context) -> None:
    if ctx.invoked_subcommand is None:
        ctx.invoke(registry_list)
```

---

## Python + Rust Extensions: Dylib Relocation Fix

### The problem

Homebrew's install pipeline runs `fix_dynamic_linkage` between `install` and
`post_install`. This step walks the entire keg cellar and calls `ruby-macho`'s
`change_dylib_id` on every Mach-O file. Rust-compiled Python extensions (`.so`
files from cryptography, jiter, pydantic-core, etc.) have compact Mach-O
headers that can't accommodate the rewritten ID, producing:

```
Error: Failed changing dylib ID of .../cryptography/hazmat/bindings/_rust.abi3.so
Updated load commands do not fit in the header
```

The extensions work fine — Python uses absolute paths and ignores the Mach-O
ID field. But the error looks like a broken install to users.

### Why common workarounds fail

| Approach | Why it fails |
|----------|-------------|
| `skip_clean "libexec"` | Only prevents cleanup, not relinking |
| `skip_relocation!` | Cask-only method, not available on Formula |
| Delete .so after pip install | Homebrew scans cellar before post_install |
| Move .so to subdir inside cellar | Homebrew walks entire keg recursively |
| `--only-binary` pip flag | Wheel installs fine but relink still processes |

There is no Formula-level mechanism to exclude specific files from relocation.
`mach_o_files` in `keg_relocate.rb` does `path.find` across the entire keg
with no exclude list.

### The fix: stage venv outside the cellar

Build the venv in `var/<name>-staging` during `install` (outside the cellar).
Homebrew's relocation step finds no `.so` files to rewrite. In `post_install`
(which runs after relocation), move the venv into `libexec/` and fix shebangs.

```ruby
class MyTool < Formula
  depends_on "python@3.12"

  def install
    # Build venv OUTSIDE the cellar to avoid dylib relocation errors
    staging = var/"mytool-staging"
    staging.mkpath
    venv = staging/"venv"

    system Formula["python@3.12"].opt_bin/"python3.12", "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "--no-cache-dir", "."

    # Wrapper references the FINAL path (won't exist until post_install)
    (bin/"mytool").write_env_script(libexec/"venv/bin/mytool",
      PATH: "#{libexec}/venv/bin:$PATH",
    )
  end

  def post_install
    staging = var/"mytool-staging"
    source = staging/"venv"
    target = libexec/"venv"

    if source.exist?
      target.rmtree if target.exist?
      target.parent.mkpath
      FileUtils.mv(source.to_s, target.to_s)
      staging.rmtree if staging.directory? && staging.children.empty?

      # Fix shebangs — they point to the staging path after pip install
      old_prefix = (var/"mytool-staging/venv").to_s
      new_prefix = target.to_s

      Dir.glob("#{target}/bin/*").each do |script|
        next unless File.file?(script) && !File.symlink?(script)
        content = File.read(script)
        if content.include?(old_prefix)
          File.write(script, content.gsub(old_prefix, new_prefix))
        end
      end

      cfg = target/"pyvenv.cfg"
      if cfg.exist?
        content = cfg.read
        cfg.write(content.gsub(old_prefix, new_prefix)) if content.include?(old_prefix)
      end
    end
  end
end
```

### Why this works

Homebrew's install pipeline:

```
install          → fix_dynamic_linkage     → post_install
(venv in var/)     (cellar has no .so)       (mv var/ → libexec/)
```

The key insight: `fix_dynamic_linkage` only scans the cellar (`Cellar/<name>/<version>/`).
Files in `var/` are outside the cellar and never touched by relocation.

### Important: post_install runs as a separate process

`post_install` is invoked via `postinstall.rb` in a new Ruby process. You
cannot pass data between `install` and `post_install` via instance variables.
Use the filesystem (e.g., `var/<name>-staging`) as the handoff mechanism.
After `brew install` finishes, `var/<name>-staging` should be cleaned up by
the `post_install` method.

---

## Release Workflow Pattern

A GitHub Actions workflow triggered on tag push handles building the sdist/
wheel and creating a GitHub release. The Homebrew formula is updated manually
after confirming the release artifact exists (formula auto-update via
`HOMEBREW_TAP_TOKEN` is the next step but requires org-level setup).

The release workflow must be on the tag push, not the branch push, so the
artifacts exist before the formula references them.
