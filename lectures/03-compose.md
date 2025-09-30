# Podman Compose


**Today's goals**: Learn the basis of using Podman Compose to manage multi-container applications.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Podman Compose](#podman-compose)
  - [1. Introduction](#1-introduction)
  - [2. Basic Concepts](#2-basic-concepts)
  - [3. My first `compose.yml`](#3-my-first-composeyml)
  - [4. A more realistic example](#4-a-more-realistic-example)
  - [5. Compose files are overridable](#5-compose-files-are-overridable)
  - [6. Best Practices](#6-best-practices)

<!-- markdown-toc end -->

---

## 1. Introduction

***Why Podman Compose?***

* Running a **single container** is simple: `podman run ...`
* But real-world applications are often made of **multiple services**:

  * Backend API
  * Database
  * Frontend
  * Cache, etc.
* Managing them individually is cumbersome and **human error-prone**.
* **Podman Compose** simplifies this by orchestrating multi-container setups with a single [YAML](https://yaml.org/spec/1.2.2/** file.


***Installation***

```bash
sudo dnf install podman-compose   # Fedora
sudo apt install podman-compose   # Debian/Ubuntu
pip install podman-compose        # Install with pip package manager
```

Check installation:

```bash
podman-compose --version
```

## 2. Basic Concepts

`podman-compose` is a tool that allows you to define and manage multi-container applications using a YAML file, similar to Docker Compose.
The main commands are:

| Command                | Description                                   |
| ---------------------- | --------------------------------------------- |
| `podman-compose up`    | Start all services                            |
| `podman-compose down`  | Stop and remove containers, networks, volumes |
| `podman-compose build` | Build all images                              |
| `podman-compose ps`    | List running services                         |
| `podman-compose logs`  | Show logs from all services                   |


**Your best friend with podman-compose**... As always, also in the case of `podman-compose`, there is the `--help` option to get a list of all available commands and options:

```bash
podman-compose --help
podmnan-compose <command> --help
```

***What is happening under the hood?***

When you run `podman-compose up`, it:

* Builds and starts all services defined in `compose.yml`
* Creates a **shared network** so containers can talk to each other
* Handles **dependencies** automatically (`depends_on`)


## 3. My first `compose.yml`

In the ['demo01'](../codes/03-podman-compose/demo01) folder, you can find a simple where there are defined two web services (nginx and apache) that are running on the same network and exposing different ports on the host.

Try to deploy it:

```bash
docker-compose up
```

And access the two web servers:

- `http://localhost:8080` (nginx)
- `http://localhost:8081` (apache)



> **Exercise**: Opening a new terminal every time you want to launch a podman-compose command is not very practical. How can you avoid this?

<details>

<summary>Solution</summary>

```
podman-compose up -d
```

Where `-d` means "detached" (run in the background).

To stop the services, you can run:

```
podman-compose down
```

</details>



## 4. A more realistic example

The previous example served to illustrate the basic usage of `podman-compose`, but it was just two conatiner services running independently. The only point of using `podman-compose` in that case was to avoid launching two `podman run` commands.

Let's relax the example a bit and see a more realistic case where we have a web application (a simple Worldpress site) that depends on a database (MariaDB**.

**What changes?**

- We have a service dependency: the web app needs the database to function.
- We need to manage **persistent data**: the database should keep its data even if the container is removed.
- We must ensure that the Worldpress services is able to connect to the database service.


In the ['demo02'](../codes/03-podman-compose/demo02) folder, you can find a `compose.yml` file that implements this scenario.


> **Exercise**: how to get rid of the persistence to start from scratch?

<details>
<summary>Solution</summary>
You can remove the volume with:

```bash
podman volume rm <volume_name>
```
or

```bash
podman-compose down -v
```

where `-v` means "remove volumes".

</details>


## 5. Compose files are overridable

You can have multiple compose files and override settings. For example, you might have a `base.yml` for common settings and a `dev.yml` for development-specific settings and a `prod.yml` for production-specific settings.

Usually to specify a different compose file (when it is not named `compose.yml` or `docker-compose.yml`), you can use the `-f` option:

```bash
podman-compose -f <filename>.yml up
```

But you can also specify multiple files, and the latter will override the former:

```bash
podman-compose -f base.yml -f dev.yml up
```
or

```bash
podman-compose -f base.yml -f prod.yml up
```


***Remark!*** The order of the files matters: settings in the later files will override those in the earlier ones!


Check the example in the ['demo03'](../codes/03-podman-compose/demo03) folder to see how it works.

## 6. Best Practices
* Use **.env** files to manage secrets and environment variables.
* Keep services **small and focused**.
* Use **volumes** for persistent data (e.g., databases).

