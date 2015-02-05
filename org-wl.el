;;; org-wl.el --- Support for links to Wanderlust messages from within Org-mode

;; Copyright (C) 2014 Cédric Chépied <cedric.chepied@gmail.com>

;; Author: Cédric Chépied <cedric.chepied@gmail.com>
;; Keywords: org, wanderlust, link
;; Homepage: http://orgmode.org
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Commentary:
;;
;; This file implements links to Wanderlust messages from within Org-mode.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Template example:
;; (add-to-list 'org-capture-templates '(("e" "Email Todo" entry
;;                                        (file+headline "~/org/myfile.org" "Tasks")
;;                                        "* TODO %^{Brief Description}\nEmail: %a\nFrom: %:from \nTo: %:to \n%?Added: %U\n" :prepend t)))


;;; Code:

(require 'org)

;; Declare external functions and variables
(declare-function elmo-folder-name-internal "elmo" (ENTITY))
(declare-function wl-summary-message-number "wl-summary" ())
(declare-function wl-summary-set-message-buffer-or-redisplay "wl-summary" (&rest ARGS))
(declare-function wl-summary-redisplay-internal "wl-summary" (&optional FOLDER NUMBER
                                                                        FORCE-RELOAD
                                                                        MIME-MODE HEADER-MODE))
(declare-function wl-folder-get-elmo-folder "wl-folder" (ENTITY &optional NO-CACHE))

(org-add-link-type "wl" 'org-wl-open)
(add-hook 'org-store-link-functions 'org-wl-store-link)

(defun org-wl-store-link ()
  "Store a link to a wl folder or message."
  (let ((buf (if (eq major-mode 'wl-summary-mode)
                 (current-buffer)
               (and (boundp 'wl-message-buffer-cur-summary-buffer)
                    wl-message-buffer-cur-summary-buffer))))
    (when buf
      (with-current-buffer buf
        (when (eq major-mode 'mime-view-mode)
          (switch-to-buffer wl-message-buffer-cur-summary-buffer))
        (when (eq major-mode 'wl-summary-mode)
          (let ((folder (elmo-folder-name-internal wl-summary-buffer-elmo-folder))
                (message-id (wl-summary-message-number)))
            (wl-summary-set-message-buffer-or-redisplay)
            (let* ((from (mail-fetch-field "from"))
                   (to (mail-fetch-field "to"))
                   (subject (mail-fetch-field "subject"))
                   (date (mail-fetch-field "date"))
                   (date-ts (and date (format-time-string
                                       (org-time-stamp-format t)
                                       (date-to-time date))))
                   (date-ts-ia (and date (format-time-string
                                          (org-time-stamp-format t t)
                                          (date-to-time date))))
                   link)
              (org-store-link-props
               :type "wl" :from from :to to
               :subject subject :message-id message-id)
              (when date
                (org-add-link-props :date date :date-timestamp date-ts
                                    :date-timestamp-inactive date-ts-ia))
              (setq link (concat "wl:" folder "#" (number-to-string message-id)))
              (org-add-link-props :link link :description subject)
              link)))))))


(defun org-wl-open (path)
  "Follow a wl message link to the specified PATH."
  (unless (string-match "\\(.*\\)#\\([0-9]+\\)" path)
    (error "Error in wl link"))
  (let* ((folder (match-string 1 path))
         (msg (string-to-number (match-string 2 path)))
         (elmo-folder (wl-folder-get-elmo-folder folder)))
    (wl-summary-redisplay-internal elmo-folder msg)
  ))


(provide 'org-wl)

;;; org-wl.el ends here
