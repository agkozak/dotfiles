#!/bin/sh
cloc --by-file-by-lang \
  --exclude-list-file=.gitignore \
  --exclude-lang="Markdown" \
  --force-lang="Bourne Again Shell",bash_profile \
  --force-lang="Bourne Again Shell",bashrc \
  --force-lang="Bourne Again Shell",inputrc \
  --force-lang="Bourne Again Shell",zprofile \
  --force-lang="Bourne Again Shell",zshenv \
  --force-lang="Bourne Again Shell",zshrc \
  --force-lang="Bourne Shell",profile \
  --force-lang="Bourne Shell",sh \
  --force-lang="Bourne Shell",shrc \
  --force-lang="C Shell",cshrc \
  --force-lang="C Shell",login_conf \
  --force-lang="vim script",exrc \
  --force-lang="vim script",vimrc \
  --force-lang="vim script",ideavimrc \
  .
