Contributing to Invoke-Build
=======================

This is the summary for contributing code, documentation, testing, and filing
issues. Please read it carefully to help making the code review process go as
smoothly as possible and maximize the likelihood of your contribution being
merged.

How to contribute
-----------------

The preferred workflow for contributing to pydicom is to fork the
[develop repository](https://github.com/mmattes/Invoke-Install) on
GitHub, clone, and develop on a branch. Steps:

1. Fork the [project repository](https://github.com/mmattes/Invoke-Install)
   by clicking on the 'Fork' button near the top right of the page. This creates
   a copy of the code under your GitHub user account. For more details on
   how to fork a repository see [this guide](https://help.github.com/articles/fork-a-repo/).

2. Clone your fork of the pydicom repo from your GitHub account to your local disk:

3. Create a ``feature`` branch to hold your development changes:

   ```bash
   $ git checkout -b my-feature
   ```

   Always use a ``feature`` branch. It's good practice to never work on the ``master`` branch!

4. Develop the feature on your feature branch. Add changed files using ``git add`` and then ``git commit`` files:

   ```bash
   $ git add modified_files
   $ git commit
   ```

   to record your changes in Git, then push the changes to your GitHub account with:

   ```bash
   $ git push -u origin my-feature
   ```

5. Follow [these instructions](https://help.github.com/articles/creating-a-pull-request-from-a-fork)
to create a pull request from your fork. This will send an email to the committers.

(If any of the above seems like magic to you, please look up the
[Git documentation](https://git-scm.com/documentation) on the web, or ask a friend or another contributor for help.)

Pull Request Checklist
----------------------

We recommend that your contribution complies with the following rules before you
submit a pull request:

-  If your pull request addresses an issue, please use the pull request title to
   describe the issue and mention the issue number in the pull request
   description. This will make sure a link back to the original issue is
   created. Use "closes #PR-NUM" or "fixes #PR-NUM" to indicate github to
   automatically close the related issue. Use any other keyword (i.e: works on,
   related) to avoid github to close the referenced issue.

-  All public methods should have informative docstrings with sample
   usage presented as doctests when appropriate.

-  Please prefix the title of your pull request with `[MRG]` (Ready for Merge),
   if the contribution is complete and ready for a detailed review. Two core
   developers will review your code and change the prefix of the pull request to
   `[MRG + 1]` on approval, making it eligible for merging. An incomplete
   contribution -- where you expect to do more work before receiving a full
   review -- should be prefixed `[WIP]` (to indicate a work in progress) and
   changed to `[MRG]` when it matures. WIPs may be useful to: indicate you are
   working on something to avoid duplicated work, request broad review of
   functionality or API, or seek collaborators. WIPs often benefit from the
   inclusion of a
   [task list](https://github.com/blog/1375-task-lists-in-gfm-issues-pulls-comments)
   in the PR description.

-  When adding additional functionality, provide at least one
   example script in the ``Examples/`` folder. Have a look at other
   examples for reference. Examples should demonstrate why the new
   functionality is useful in practice.

Filing bugs
-----------
We use Github issues to track all bugs and feature requests; feel free to
open an issue if you have found a bug or wish to see a feature implemented.

It is recommended to check that your issue complies with the
following rules before submitting:

-  Verify that your issue is not being currently addressed by other
   [issues](https://github.com/mmattes/Invoke-Install/issues?q=)
   or [pull requests](https://github.com/mmattes/Invoke-Install/pulls?q=).

-  Please ensure all code snippets and error messages are formatted in
   appropriate code blocks.
   See [Creating and highlighting code blocks](https://help.github.com/articles/creating-and-highlighting-code-blocks).

-  Please include your operating system type version number, as well
   as your Powershell version.

  ```ps
  $PSVersionTable
  (Get-Module Invoke-Install).Version
  ```

-  please include a [reproducible](http://stackoverflow.com/help/mcve) code
   snippet or link to a [gist](https://gist.github.com). If an exception is
   raised, please provide the traceback.

New contributor tips
--------------------

A great way to start contributing to Invoke-Install is to pick an item
from the list of [Easy issues](https://github.com/mmattes/Invoke-Install/issues?labels=Easy)
in the issue tracker. Resolving these issues allow you to start
contributing to the project without much prior knowledge. Your
assistance in this area will be greatly appreciated by the more
experienced developers as it helps free up their time to concentrate on
other issues.

Documentation
-------------

We are glad to accept any sort of documentation: function docstrings,
reStructuredText documents (like this one), tutorials, etc.
reStructuredText documents live in the source code repository under the
``Doc/`` directory.