# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ]; 
  #boot.kernelParams = [ "intel_pstate=nohwp" ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev"; 
  boot.loader.grub.efiSupport = true; 
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = [
   { name = "root";
     device = "/dev/disk/by-uuid/ddb70a55-f123-461d-a4c1-a42a393b61fa";
     preLVM = false;
     allowDiscards = true;
   }
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a6670d72-9bdf-4c62-b397-d35c8c1356ef";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" "discard" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4F4E-282E";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/699fec01-9969-4279-bc7c-8f64252e40b0"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = "powersave";
}
