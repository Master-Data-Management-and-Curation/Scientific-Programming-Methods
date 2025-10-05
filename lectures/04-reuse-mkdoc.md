# Reuse & MkDocs tools

**Today's goals**: Get in touch with two very useful tools for any project that you may be involved in:
 - [Reuse](https://reuse.software/) - a tool to help you comply with best practices regarding licensing of your project
 - [MkDocs](https://www.mkdocs.org/) - a static site generator that's geared towards project documentation

For both of theese tools, we will go through a quick introduction, be aware that both tools have a lot more features than we will cover here and are extensively documented on their respective websites.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Reuse & MkDocs tools](#reuse--mkdocs-tools)
  - [Reuse](#reuse)
    - [R.0. Installation](#r0-installation)
    - [R.1. Usage](#r1-usage)
    - [R.2. Example](#r2-example)
      - [R.2.1. Check compliance](#r21-check-compliance)
      - [R.2.2. Download licenses](#r22-download-licenses)
      - [R.2.3. Annotate files... text files](#r23-annotate-files-text-files)
      - [R.2.4. Annotate files... Non-text files.](#r24-annotate-files-non-text-files)
  - [MkDocs](#mkdocs)
    - [M.0. Installation](#m0-installation)
    - [M.1. Usage](#m1-usage)
    - [M.2. Example](#m2-example)
      - [M.2.1. Create a new mkdocs project](#m21-create-a-new-mkdocs-project)
      - [M.2.2. Serve the documentation](#m22-serve-the-documentation)
      - [M.2.3. Build the static site](#m23-build-the-static-site)
      - [M.2.4. Deploy to GitHub Pages](#m24-deploy-to-github-pages)

<!-- markdown-toc end -->



## Reuse

`reuse` its a very simple but at the same time powerful and useful tool to help you comply with best practices regarding licensing of your project. It is a project of the [FSFE](https://fsfe.org/) and is recommended by the [Open Source Initiative](https://opensource.org/).

### R.0. Installation

`reuse` is a python packages, so the easiest way to install it is using `pip`:

```bash
pip install reuse
```

However, it is also available via package managers for various distributions, e.g. `apt`, `dnf`, `brew`, etc. and it is even distributed as a [container image](https://hub.docker.com/r/fsfe/reuse).

```bash
# Alternative installation methods
apt install reuse  # Debian-based
dnf install reuse  # rhel-based
podman pull docker.io/fsfe/reuse:latest  # Container image
# ...
```

### R.1. Usage

The basic usage of `reuse` is very simple and relies bascally on tree commands:

- `reuse download` - to download license texts for your project. A complete list of supported licenses can be found [here](https://spdx.org/licenses/).

- `reuse annotate` - to annotate your source files with license information. The sintax for this command is:

  ```bash
  reuse annotate --license "<license>" --copyright "<name&surname or company> <email>" "<file(s)>
  ```

  For example:

  ```bash
  reuse annotate -- license " AGPL-3.0-or-later" --copyright "James Kirk james.t.kirk@starfleet.org" logbook/*.txt
  ```

  Note that the `<file(s)>` argument can be a single file, multiple files or even a directory (in which case all files in the directory will be annotated) and supports wildcards!

- `reuse lint` - to check your project for compliance with the REUSE specification.

### R.2. Example

Let's try to use `reuse` in a small example project. For the pourpose of this example, we will use the [`reuse-example`](https://github.com/fsfe/reuse-example) project:

```bash
git clone https://github.com/fsfe/reuse-example.git

cd reuse-example

# Checkout to the non-compliant version
git checkout noncompliant
```


#### R.2.1. Check compliance

If you use the `reuse lint` commant now, you will see that the project is not compliant with the REUSE specification:

```bash
reuse lint
# MISSING COPYRIGHT AND LICENSING INFORMATION

The following files have no copyright and licensing information:
* .gitignore
* Makefile
* README.md
* img/cat.jpg
* img/dog.jpg
* src/main.c

# SUMMARY

* Bad licenses: 0
* Deprecated licenses: 0
* Licenses without file extension: 0
* Missing licenses: 0
* Unused licenses: 0
* Used licenses: 0
* Read errors: 0
* Files with copyright information: 0 / 6
* Files with license information: 0 / 6

Unfortunately, your project is not compliant with version 3.3 of the REUSE Specification :-(


# RECOMMENDATIONS

* Fix missing copyright/licensing information: For one or more files, the tool
  cannot find copyright and/or licensing information. You typically do this by
  adding 'SPDX-FileCopyrightText' and 'SPDX-License-Identifier' tags to each
  file. The tutorial explains additional ways to do this:
  <https://reuse.software/tutorial/>
```

Note that the lint commands is very verbose, providing detailed information about the issues found and how to fix them.

#### R.2.2. Download licenses

Before being able to annotate the files with `reuse annotate`, reuse needs to download the license texts for the licenses we want to use in our project.

Let's say that we want to use `GPL-3.0-or-later` for the source code files and `CC-BY-4.0` and `CC0-1.0` for the image files. We can download the license texts using the `reuse download` command:

```bash
reuse download GPL-3.0-or-later
# You can also download multiple licenses at once!
reuse download CC-BY-4.0 CC0-1.0
```

> Remark: Choosing the right license for your project is not a trivial task and should be done with care. The licenses used in this example are just for demonstration purposes and may not be suitable for your project.
> More important, rember that code, data and other assets in a project can be licensed under different licenses!


#### R.2.3. Annotate files... text files

- The `reuse annotate` command is used to add the necessary license and copyright information to the files in your project.

- It will add the information as comments in the files, so the syntax will depend on the file type. For example, for C files it will use `/* ... */` comments, for Python files it will use `# ...` comments, etc.

- Usually `reuse` is smart enough to detect the file type and use the appropriate comment syntax, but you can also specify it manually using the `--comment-style` option.


Let's analize as an example the `Makefile`:

```
cat Makefile
helloworld: src/main.o
	gcc src/main.o -o helloworld

src/main.o: src/main.c
	gcc -c src/main.c -o src/main.o

```

And let's annotate it with the `GPL-3.0-or-later` license and a copyright:

```bash
reuse annotate --license "GPL-3.0-or-later" --copyright "<name_surname> <email>" Makefile
```

And let's inspect the file again:

```
cat Makefile
# SPDX-FileCopyrightText: 2025 <name_surname> <email>
#
# SPDX-License-Identifier: GPL-3.0-or-later

helloworld: src/main.o
	gcc src/main.o -o helloworld

src/main.o: src/main.c
	gcc -c src/main.c -o src/main.o
```

See? the necessary information has been added as comments at the top of the file!

Let's have a look again at the `reuse lint` command:

```bash
reuse lint

[...]
* Files with copyright information: 1 / 6
* Files with license information: 1 / 6
[...]
```

As you can see, now one file is compliant.


> ***Exercise:*** Try to annotate the rest of the text files in the project with the appropriate license and copyright information. In particular `README.md` and `src/main.c` file remains. Use `GPL-3.0-or-later` for the `src/main.c` file and `CC-BY-4.0` for the `README.md` file.

<details>
<summary>Solution</summary>
```bash
reuse annotate --license "GPL-3.0-or-later" --copyright "<name_surname> <email>" src/main.c
reuse annotate --license "CC-BY-4.0" --copyright "<name_surname> <email>" README.md
```
</details>

#### R.2.4. Annotate files... Non-text files.

We have said that `reuse annotate` adds information as comments at the top of the files. But what about non-text files, like images, binaries, etc.?

There are two ways to handle this:

- ***Option A.***: for each non-text file, create a corresponding `.license` file with the same name and the necessary information. For example, for `img/cat.jpg`, create a file named `img/cat.jpg.license` with the following content:

  ```
  SPDX-FileCopyrightText: 2025 <name_surname> <email>

  SPDX-License-Identifier: CC0-1.0
  ```

  This can be done using the `reuse annotate` exactly as before:

  ```bash
    reuse annotate --license "CC0-1.0" --copyright "<name_surname> <email>" img/cat.jpg.license
  ```

- ***Option B.***: use a unique `REUSE.toml` file in the root of the project to specify the license and copyright information for all non-text files in the project. The syntax of the `REUSE.toml` file is as follows:

  ```toml
  version = 1

  [[annotations]]
  path = "img/cat.jpg"
  SPDX-FileCopyrightText = "<year> <name> <surname> <email>"
  SPDX-License-Identifier = "CC-BY-4.0"

  [[annotations]]
  path = "img/dog.jpg"
  SPDX-FileCopyrightText = "<year> <name> <surname> <email>"
  SPDX-License-Identifier = "CC0-1.0"
  ```

## MkDocs

### M.0. Installation

`mkdocs` is distributed as a python package, so the easiest way to install it is using `pip`:

```bash
pip install mkdocs
```

However, it is also available via package managers for various distributions, e.g. `apt`, or `dnf`.


### M.1. Usage

The basic usage of `mkdocs` is very simple and relies basically on three commands:

- `mkdocs new <project_name>` - to create a new mkdocs project. This will create a new directory with the given name and populate it with the necessary files and directories.

- `mkdocs serve` - to start a local development server. This will allow you to preview your documentation in your web browser and see the changes you make in real-time.

- `mkdocs build` - to build the static site. This will generate the static files for your documentation in the `site` directory.


### M.2. Example

Create a empty repository on github

```bash
REMOTEURL='https://github.com/<YOUR_GITHUB_USERNAME>/<YOUR_GITUHUB_REPOSITORY_NAME>'
```


#### M.2.1. Create a new mkdocs project

```bash
mkdocs new <YOUR_GITHUB_REPOSITORY_NAME>
```

Now go into the created directory and initialize a git repository:

```
cd <YOUR_GITHUB_REPOSITORY_NAME>
git init
git remote add origin git@github.com:<YOUR_GITHUB_USERNAME>/<YOUR_GITUHUB_REPOSITORY_NAME>.git
```

#### M.2.2. Serve the documentation

Now you can start the local development server:

```bash
mkdocs serve
```

You can see that editing the `docs/index.md` file will update the page in real-time in the browser at `localhost:8000`.

#### M.2.3. Build the static site

When you are happy with your documentation, you can build the static site:

```bash
mkdocs build
```

This will generate the static files for your documentation in the `site` directory. This is the directory that you will need to deploy to your web server or hosting service.

#### M.2.4. Deploy to GitHub Pages

`mkdocs` has a built-in command to deploy your documentation to GitHub Pages:

```bash
mkdocs gh-deploy
```

This will work only with github, and it will create a `gh-pages` branch in your repository and push the contents of the `site` directory to that branch.

Moreover it will make the documentation available at `https://<YOUR_GITHUB_USERNAME>.github.io/<YOUR_GITUHUB_REPOSITORY_NAME>/`.



