{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption optionals types;
  cfg = config.programs.guiFileManager;

  desktopId = "org.gnome.Nautilus.desktop";
  directoryMimeTypes = [
    "inode/directory"
    "application/x-gnome-saved-search"
  ];
in
{
  options.programs.guiFileManager = {
    enable = mkEnableOption "a polished graphical file manager";

    package = mkOption {
      type = types.package;
      default = pkgs.nautilus;
      defaultText = "pkgs.nautilus";
      description = "GUI file manager package to install.";
    };

    setAsDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Use the GUI file manager as the default app for directories.";
    };

    enablePreviewer = mkOption {
      type = types.bool;
      default = true;
      description = "Install GNOME Sushi for quick file previews from Nautilus.";
    };

    enableArchiveIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Install File Roller so Nautilus can handle archives nicely.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages to install alongside the file manager.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages =
        [ cfg.package ]
        ++ optionals cfg.enablePreviewer [ pkgs.sushi ]
        ++ optionals cfg.enableArchiveIntegration [ pkgs.file-roller ]
        ++ cfg.extraPackages;

      # Small quality-of-life defaults for a clean desktop-oriented setup.
      dconf.enable = true;
      dconf.settings = {
        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "icon-view";
          migrated-gtk-settings = true;
          search-filter-time-type = "last_modified";
          show-create-link = true;
          show-delete-permanently = true;
        };

        "org/gnome/nautilus/icon-view" = {
          default-zoom-level = "medium";
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          sort-directories-first = true;
          show-hidden = false;
        };
      };
    }

    (mkIf cfg.setAsDefault {
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = lib.genAttrs directoryMimeTypes (_: desktopId);
      xdg.mimeApps.associations.added = lib.genAttrs directoryMimeTypes (_: desktopId);
    })
  ]);
}
