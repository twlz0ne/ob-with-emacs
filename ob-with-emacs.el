;;; ob-with-emacs.el --- Execute emacs-lisp src block in in a separate Emacs process -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Gong Qijian <gongqijian@gmail.com>

;; Author: Gong Qijian <gongqijian@gmail.com>
;; Created: 2019/11/15
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (with-emacs "0.3.0))
;; URL: https://github.com/twlz0ne/ob-with-emacs
;; Keywords: tool

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Execute emacs-lisp src block in in a separate Emacs process.
;;
;; Usage:
;;
;; Add `:with-emacs "/path/to/{version}/emacs"` (the path is optional)
;; to the header-args of emacs-lisp src block, for example:
;;
;; ```
;; #+BEGIN_SRC emacs-lisp :results output :with-emacs
;; (print emacs-version)
;; #+END_SRC
;; ```
;;
;; Or if there are partially applied functions defined (see `with-emacs-define-partially-applied'):
;;
;; ```
;; #+BEGIN_SRC emacs-lisp :results output :with-emacs-24.3
;; (print emacs-version)
;; #+END_SRC
;; ```
;;
;; See README.md for more information.

;;; Change Log:

;;  0.1.0  2019/11/15  Initial version.

;;; Code:

(require 'with-emacs)

(defun ob-with-emacs--sandbox-parameter (params)
  (catch 'break
    (dolist (name (append with-emacs-partially-applied-functions '(with-emacs)))
      (let* ((key (intern (format ":%s" name)))
             (param (assq key params)))
        (when param
          (throw 'break param))))))

;; (ob-with-emacs--sandbox-parameter '((:with-emacs . "/path/to/emacs")))

;;;###autoload
(defalias 'org-babel-execute:emacs-lisp-in-sandbox 'ob-with-emacs-org-babel-execute-elisp-src-block)

;;;###autoload
(defun ob-with-emacs-org-babel-execute-elisp-src-block (&optional orig-fn body params)
  "Like `org-babel-execute:emacs-lisp', but run in sandbox.

Original docstring for org-babel-execute:emacs-lisp:

Execute a block of emacs-lisp code with Babel."
  (cond
    ;; If this function is not called as advice, do nothing
    ((not orig-fun)
     (warn "ob-with-emacs-org-babel-execute-elisp-src-block is no longer needed in org-ctrl-c-ctrl-c-hook")
     nil)
    (t
     (let ((emacs-param (ob-with-emacs--sandbox-parameter params)))
       (cond
        ;; If there is no :playonline parameter, call the original function
        ((not emacs-param)
         (funcall orig-fun body params))
        ;; If there is no :with-emacs parameter, call the original function
        (t
         (save-window-excursion
           (let* ((lexical (cdr (assq :lexical params)))
                  (result-params (cdr (assq :result-params params)))

                  (body (format (if (member "output" result-params)
                                    "(%s %s\n (with-output-to-string %s\n))"
                                  "(%s %s\n (progn %s\n))")
                                (substring (format "%s" (car emacs-param)) 1)
                                (if (cdr emacs-param)
                                    (format ":path %S" (cdr emacs-param))
                                  "")
                                (org-babel-expand-body:emacs-lisp body params)))
                  (result (eval (read (if (or (member "code" result-params)
                                              (member "pp" result-params))
                                          (concat "(pp " body ")")
                                        body))
                                (if (listp lexical)
                                    lexical
                                  (member lexical '("yes" "t"))))))
             (org-babel-result-cond result-params
               (let ((print-level nil)
                     (print-length nil))
                 (if (or (member "scalar" result-params)
                         (member "verbatim" result-params))
                     (format "%S" result)
                   (format "%s" result)))
               (org-babel-reassemble-table
                result
                (org-babel-pick-name (cdr (assq :colname-names params))
                                     (cdr (assq :colnames params)))
                (org-babel-pick-name (cdr (assq :rowname-names params))
                                     (cdr (assq :rownames params)))))))))))))

(advice-add 'org-babel-execute:emacs-lisp :around 'org-babel-execute:emacs-lisp-in-sandbox)

(provide 'ob-with-emacs)

;;; ob-with-emacs.el ends here
