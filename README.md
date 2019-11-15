# ob-with-emacs

Execute elisp code blocks in a separate Emacs process

## Installation

Install [with-emacs](https://github.com/twlz0ne/with-emacs.el) first, then clone this repository and add the following to your `.emacs`:

```elisp
(add-to-list 'load-path (expand-file-name "~/.emacs.d/site-lisp/ob-with-emacs"))
(require 'ob-with-emacs)
```

## Usage

Add `:with-emacs "/path/to/{version}/emacs"` (the path is optional)
to the header-args of emacs-lisp src block, for example:

```
#+BEGIN_SRC emacs-lisp :results output :with-emacs
(print emacs-version)
#+END_SRC
```

Or if there are partially applied functions defined (see `with-emacs-define-partially-applied'):

```
#+BEGIN_SRC emacs-lisp :results output :with-emacs-24.3
(print emacs-version)
#+END_SRC
```
