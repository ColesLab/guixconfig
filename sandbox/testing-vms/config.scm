(use-modules (gnu)
             (gnu home)
             (gnu home services shells)
             (gnu home services dotfiles)
             (guix channels))

(use-system-modules keyboard vm)
(use-package-modules package-management wm)
(use-service-modules guix spice desktop xorg)

(define my-channels
  (cons* (channel
          (name 'nonguix)
          (url "https://gitlab.com/nonguix/nonguix")
          (introduction
           (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
             "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
         %default-channels))

(define my-home
  (home-environment
   (packages (list qtile))
   (services (list
              (service home-dotfiles-service-type
                       (home-dotfiles-configuration
                        (source-directory "/home/cole/")
                        (directories '(".dotfiles"))
                        (layout 'stow)))
              (service home-bash-service-type)))))

(define test-os
  (operating-system
    (host-name "crafter")
    (timezone "Europe/Athens")
    (locale "en_US.utf8")
    (keyboard-layout (keyboard-layout "us" "altgr-intl" #:model "thinkpad"))

    ;; This will be replaced
    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets '("/boot/efi"))
                 (keyboard-layout keyboard-layout)))

    ;; Guix doesn't like it when there isn't a file-systems
    ;; entry, so add one that is meant to be overridden
    (file-systems (cons*
                   (file-system
                     (mount-point "/tmp")
                     (device "none")
                     (type "tmpfs")
                     (check? #f))
                   %base-file-systems))

    (users (cons (user-account
                  (name "cole")
                  (password (crypt "crafter" "$6$abc"))
                  (group "users")
                  (home-directory "/home/cole")
                  (supplementary-groups '("wheel"
                                          "netdev"
                                          "kvm"
                                          "tty"
                                          "input"
                                          "audio"
                                          "video")))
                 %base-user-accounts))

    (packages (append (map specification->package
                           '("git"
                             "vim"
                             "emacs-no-x-toolkit"))
                      %base-packages))

    (services (cons* (service spice-vdagent-service-type)
                     (service guix-home-service-type
                              `(("cole" ,my-home)))
                     (modify-services %desktop-services
                                      (delete gdm-service-type)
                                      (guix-service-type
                                       config => (guix-configuration
                                                  (inherit config)
                                                  (channels my-channels)
                                                  (guix (guix-for-channels my-channels)))))))))

;; Configure `test-os` to run in a QEMU VM
(virtualized-operating-system test-os)
