{ pkgs, ... }:
{
 # programs.gpg = {
#   enable = true;
#
#   # https://support.yubico.com/hc/en-us/articles/4819584884124-Resolving-GPG-s-CCID-conflicts
#   scdaemonSettings = {
#     disable-ccid = true;
#   };
#
#   # https://github.com/drduh/config/blob/master/gpg.conf
#   settings = {
#     personal-cipher-preferences = "AES256 AES192 AES";
#     personal-digest-preferences = "SHA512 SHA384 SHA256";
#     personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
#     default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
#     cert-digest-algo = "SHA512";
#     s2k-digest-algo = "SHA512";
#     s2k-cipher-algo = "AES256";
#     charset = "utf-8";
#     fixed-list-mode = true;
#     no-comments = true;
#     no-emit-version = true;
#     keyid-format = "0xlong";
#     list-options = "show-uid-validity";
#     verify-options = "show-uid-validity";
#     with-fingerprint = true;
#     require-cross-certification = true;
#     no-symkey-cache = true;
#     use-agent = true;
#     throw-keyids = true;
#   };
# };
#
# services.gpg-agent = {
#   enable = true;
#
#   # https://github.com/drduh/config/blob/master/gpg-agent.conf
#   defaultCacheTtl = 60;
#   maxCacheTtl = 120;
#   pinentryPackage = pkgs.pinentry-curses;
#   extraConfig = ''
#     ttyname $GPG_TTY
#   '';
# };
home.stateVersion = "24.05";

home.packages = [ pkgs.claude-code ];

programs.heimdall = {
  enable = true;
  packageNames = [ "daemon" "wrapper" "ctl" "ui" ];

  daemon = {
    bindHost = "127.0.0.1";
    port     = 49322;
    dataDir  = "~/.local/share/heimdall";
  };

  wrapper = {
    daemonUrl        = "http://127.0.0.1:49322";
    agentName        = "pi";
    defaultAgent     = "pi";
    displayName      = "{instance}";
    requestedAccessMode = "main";
    tmuxSession      = "ham-agents";
    tmuxWindowPrefix = "agent";
    agentRunDir      = "~/.local/share/heimdall/agent-runs";
    project          = "default";

    agentCommands = {
      pi = {
        command       = [ "pi" ];
        yoloFlags     = [];
        promptFlags   = [];
        starterPrompt = "First, run: {ctl_bin} --token {token} start-success. Then read your bootstrap file (AGENTS.md or CLAUDE.md) for context, identity, and what you can do.";
        models = {
          flag   = "--model";
          cheap  = "openai-codex/gpt-5.3-codex-spark";
          normal = "sonnet";
          smart  = "opus";
        };
        startupDetection = {
          enabled       = false;
          readyOnLaunch = true;
        };
      };

      claude = {
        command       = [ "claude" ];
        yoloFlags     = [ "--dangerously-skip-permissions" ];
        promptFlags   = [];
        starterPrompt = "First, run: {ctl_bin} --token {token} start-success. Then read your bootstrap file (AGENTS.md or CLAUDE.md) for context, identity, and what you can do.";
        bootstrap = {
          agentsMd = {
            name    = "CLAUDE.md";
            content = [ "IDENTITY" "GUIDANCE" "PROJECT" "MEMORY" ];
          };
          memoryMd.name = "MEMORY.md";
          skills = {
            relativeDir = "skills";
            filename    = "SKILL.md";
          };
        };
        models = {
          flag   = "--model";
          cheap  = "haiku";
          normal = "sonnet";
          smart  = "opus";
        };
        startupDetection = {
          enabled                 = true;
          startupProbeSeconds     = 20;
          captureIntervalMs       = 500;
          autoEnterPatterns       = [
            "Yes, I trust this folder"
            "WARNING: Claude Code running in Bypass Permissions mode"
          ];
          autoEnterPreKeys        = [ "" "Down" ];
          blockedPatterns         = [ "Enter auto mode" ];
          startupUnknownIsBlocked = false;
          sanitizedReasonMapping  = [
            "trust=Claude directory trust prompt"
            "trust=Claude directory trust prompt"
            "bypass=Claude bypass permissions warning"
            "confirm=Claude interactive confirm prompt"
          ];
        };
      };

      codex = {
        command       = [ "codex" ];
        yoloFlags     = [];
        promptFlags   = [];
        starterPrompt = "First, run: {ctl_bin} --token {token} start-success. Then read your bootstrap file (AGENTS.md or CLAUDE.md) for context, identity, and what you can do.";
        models = {
          flag   = "-m";
          cheap  = "gpt-5-mini";
          normal = "gpt-5";
          smart  = "gpt-5-pro";
        };
      };
    };
  };

  ctl.daemonUrl = "http://127.0.0.1:49322";
};
}
