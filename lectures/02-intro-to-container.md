# Introduction to containers: practical session

**Today's goals**: Learn the basis of containers, get in touch with Podman and understand how to use it, common pitfalls and become able to mangage very simple applications through containers.


<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Introduction to containers: practical session](#introduction-to-containers-practical-session)
  - [0. The most useful and important commands](#0-the-most-useful-and-important-commands)
  - [1. First step in the real containers world](#1-first-step-in-the-real-containers-world)
  - [2. Why does my container exit immediately? (not-)Interactive mode!](#2-why-does-my-container-exit-immediately-not-interactive-mode)
  - [3. How to see services running inside a container? Port forwarding!](#3-how-to-see-services-running-inside-a-container-port-forwarding)
  - [4. Where are my files? Persistency and volumes!](#4-where-are-my-files-persistency-and-volumes)
  - [5. What if I can not find any suitable image? Built it by yourself!](#5-what-if-i-can-not-find-any-suitable-image-built-it-by-yourself)
    - [5-bis. How can I share my image with colleagues? Push it to a registry!](#5-bis-how-can-i-share-my-image-with-colleagues-push-it-to-a-registry)
  - [6. How to inspect a container/image? Entrypoints and CMD](#6-how-to-inspect-a-containerimage-entrypoints-and-cmd)

<!-- markdown-toc end -->

<details>
<summary>Using a remote connection?</summary>

If you using a remote connection, such as the remote VM provided for the course, remeber to set properly your ssh-configuraition!

Your `$HOME/.ssh/config` file should contains
```config
Host orfeo-login
    HostName 195.14.102.215
    User <YOUR_USER_IN_ORFEO>
    IdentityFile ~/.ssh/<YOUR_KEY_FILE_NAME>

Host vm
    HostName 10.128.12.<YOUR_VM_ID>
    User root
    IdentityFile ~/.ssh/<YOUR_KEY_FILE_NAME>
    ProxyJump orfeo-login
    LocalForward 8080 10.128.12.<YOUR_VM_ID>:8080
    LocalForward 8081 10.128.12.<YOUR_VM_ID>:8081
    LocalForward 8888 10.128.12.<YOUR_VM_ID>:8888
```

Otherwise, you will not be able to access with your web browser the services running inside the containers, such as the jupyter notebook.


Moreover, the provided VMs comes with ubuntus. Once you have intalled podman with

```bash
apt install podman
```

Edit the `containers/containers.conf` file and set:

```ini
[registries.search]
registries = ['docker.io', 'quay.io', 'registry.fedoraproject.org']
```

</details>

## 0. The most useful and important commands

One of the most useful commands and the first one you should try are

```bash
man podman

podman --help
```

The first one will give you the man page, while the second one will give you a quick overview of the most important commands. In most of the cases, when you are experiencing issues, the solution to your problem can be found there!

Note that both of these commands have also dedicated help pages for each podman operation you are trying to perform. For example:

```bash
podman run --help

man podman-pull
```

## 1. First step in the real containers world

Now we are ready to run our first container. The `hello-world` image is a very simple image that will print a message and exit. It is a good way to test if your container engine is working properly.

```bash
podman run hello-world:latest
```

Why `latest`? It is a tags. Tags are used to identify different versions of the same image (think like how they works in git). We can change it, taking for example a specific version of the image:

```bash
podman run hello-world:linux
```

What if we don't specify a tag? Podman will use `latest` by default.

```bash
# Same as   podman run hello-world:latest
podman run hello-world
```

## 2. Why does my container exit immediately? (not-)Interactive mode!

We have sayd that one of the aims of containers is to solve the dependency hell (a.k.a. "it works on my machine" problem).
So now, let's try to run a reasonable old version of Python, e.g., `python3.6.15`

You will not be able to install it on your machine with `apt` or `dnf`, but there is a container image for that!
So first of all, let's pull the image!

```bash
podman pull python:3.6.15
```

And now try to run it

```bash
podman run python:3.6.15
```

***Why nothing happens?***

By default, podman/docker runs the container in a non-interactive mode. Our container:

i. spawed (a process has been started)
ii. the process finished immediately (because there is nothing to do)
iii. the container exited

We can check that there were no errors, using the `$?` variable, that contains the exit code of the last command executed

```bash
echo $?

# should print 0, meaning no-error
```

In fact if we use 'podman ps' command, which will print all the running containers, we will see that there are no containers running

```bash
podman ps

CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
```

But have a look at the `podman ps --help`. There is a `-a` option that will show all the containers, including the exited ones, which are not shown by default!

```bash
podman ps -a
CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS                    PORTS       NAMES
a0c113e92d73  docker.io/library/python:3.6.15  python3     5 seconds ago  Exited (0) 6 seconds ago              strange_antonelli
```

So, now the question is ***how can we run the container in interactive mode?***
 $\rightarrow$ Once again, `podman run --help` is our friend!

There are two options, that cobined toghether will allow us to run the container in interactive mode:

- `-i` or `--interactive`: Make STDIN available to the contained process (even if not attached)
- `-t` or `--tty`: Allocate a pseudo-TTY, which means that we will be able to interact with the container process through a terminal

So, let's try again

```bash
podman run -it python:3.6.15
```

It works! We are now inside the container, and we can use Python 3.6.15!

```python
>>> import sys
>>> print(sys.version)
3.6.15 (default, Dec 21 2021, 12:03:22)
[GCC 10.2.1 20210110]
```

## 3. How to see services running inside a container? Port forwarding!

Let's raise the bar a bit. Now we want to run a jupyter notebook!

*Recap*: Jupyter notebook is a web application that allows you to create python notebooks. Its operation is based on a client-server architecture, there is a server that runs the code and takes care of everything, and a client, which is how the user interacts with the server, through a web browser.

Normally, to run a jupyter notebook, you would do something like this:

```bash
jupyter notebook
```
and open your web browser at `http://localhost:8888` (actually copy-pasting the URL with the token that is printed in the terminal).

Now, let's try to run a jupyter notebook inside a container. We will use the `jupyter/base-notebook` image, which is a very minimal image that contains only the jupyter notebook and its dependencies.

```bash
# Pull the image
podman pull jupyter/base-notebook:python-3.8.8
# Run the container
podman run jupyter/base-notebook:python-3.8.8
```

And try to open your web browser at `http://localhost:8888` ... Does it work?

***Why it does not work?***

$\rightarrow$ The reason is that the jupyter notebook server is running inside the container, and it is not accessible from outside the container. In fact, the process running inside the container "is not aware" that it is running in a sandboxed environment, and is listening on its own localhost on the default port 8888.

*So, how can we make the jupyter notebook server accessible from outside the container?*
$\rightarrow$ We need to use port forwarding! Again, `podman run --help` is our friend, and among the various options we can find:

- `-p` or `--publish`: Publish a container's port(s) to the host

The syntax is `-p <host_port>:<container_port>`, so in our case we need to forward the container's port 8888 to any port on the host (let's use 8080).

```bash
podman run -p 8080:8888 jupyter/base-notebook:python-3.8.8
```

And try again to open your web browser at `http://localhost:8080` ... Now it works!


## 4. Where are my files? Persistency and volumes!

- Use the previous command to run the jupyter notebook container, and try to create some notebooks (by default there is a `work` directory where you can create your notebooks).
- Stop the container with: `podman stop <container_id>`, where `<container_id>` is the id of the container you can find with `podman ps`
- Start the new container again with the same command as before and refresh the browser page. This is not something weired, image that you have to stop your computer and restart, or finish a work started yesterday...


***Where are all my very important files?***

$\rightarrow$ Remember? Containers are ephemeral by default. When a container is stopped, all the changes made to the filesystem inside the container are lost.

If I can not save my files, what is the point of using containers? I don't want to lose my work and start again every time!

Off course, there is a way to persist data in containers, and it is called volumes!
A volume is a directory on the host that is mounted inside the container. Any changes made to the files in the volume are persisted on the host, even if the container is stopped or deleted.

So first of all, let's create a directory on the host where we will store our notebooks:

```bash
mkdir mydata
```

To mount a volume, you can use the `-v` or `--volume` option of the `podman run` command. The syntax is:

```bash
podman run -v <host_dir>:<container_dir> [...]
```

So in our case we need to mount the `mydata` directory on the host to the `/home/jovyan/work` directory inside the container. More detail about why to mount in that specific directory can be found in the section [`6.`](#6-how-to-inspect-a-containerimage-entrypoints-and-cmd).


Try to run the container again with the following command:

```bash
podman run --userns=keep-id -p 8888:8888 \
      -v $(pwd)/mydata:/home/jovyan/work \
      jupyter/base-notebook:python-3.8.8
```

- Create some notebooks
- Stop the container
- See? your notebooks are still there! You can access them in the `mydata` directory on the host.
- Start the container again and refresh the browser page. Your notebooks are still there! and you can continue your work from where you left it!


About the `--userns=keep-id** option: it is used to map the user inside the container to the user on the host. This is important because if you create files inside the container, they will be owned by the user inside the container. This is usually not a problem when the process inside the container is running as root, which is the default behaviour of most of the images but not this one. If you omit this option, the non-user inside the container will not have the privileges to create files in the mounted directory on the host.


**Exercise**: Try to run a jupyter notebook mounting a volume with the [demo.ipynb](../codes/02-introduction-to-container/demo/demo.ipynb) file. Does it work? Why?


<details>

<summary>Solution</summary>

```bash
podman run --userns=keep-id -p 8888:8888 \
    -v ./demo/demo.ipynb:/home/jovyan/work/demo.ipynb \
    jupyter/base-notebook:python-3.8.8
```

</details>



## 5. What if I can not find any suitable image? Built it by yourself!

Nice, now we are able to run a jupyter notebook properly, but what if we need some additional packages and libraries that are not included in the base image? For example, now we want to use `numpy` and `matplotlib` in our notebooks.

- Easy solution: Search for another image. Simple, but:
  - May not exists
  - The only suitable that you can find is bloated with unnecessary stuff

*Better solution: Build your own image!*

Remeber the pipeline we have seen in the introduction?

```
Dockerfile  -->  Image  -->  Container
```

Hence, the first step is to create a `Dockerfile`, which is a text file that contains the instructions to build an image.
Have a look at [this file](../codes/02-introduction-to-container/Dockerfile)

> ! hint: Dockerfiles have a man page too!
> ```
> man Dockerfile
> ```


The builds command works like this:

```bash
podman build <context> -f <path_to_dockerfile> -t <image_name>:<tag>
```

Where:

- `<context>` is the directory where the build will be executed. It is important when you have `COPY` or `ADD` directives in your Dockerfile. To keep things simple, we will use `.` (the current directory) as context.
- `<path_to_dockerfile>` is the path to the Dockerfile. If the file is named `Dockerfile` and is in the context directory, you can omit `-f <path_to_dockerfile>`.
- `<image_name>:<tag>` is the name and tag of the image you are building. If you omit the tag, `latest` will be used by default.

So, to build our image, we can use the following command:

```bash
podman build . -t my-jupyter-image:latest
```
<details>
<summary>Advanced considerations about images</summary>

> See what is appening:
>
> The first time:
> ```
>    podman build . -f Dockerfile -t my-jupyter-image:latest
>    STEP 1/8: FROM fedora:42
>    STEP 2/8: RUN dnf update -y &&     dnf -y --setopt=install_weak_deps=False install     python3     python3-pip &&     dnf clean all -y &&     rm -rf /var/cache* &&     rm -rf /var/log/dnf.*
>    --> Using cache 8c7d26298d302c379af212f9ea93238360a5912607d43980b2dd2ba9938290a6
>    --> 8c7d26298d30
>    STEP 3/8: RUN pip3 install --no-cache-dir     jupyterlab     numpy     matplotlib
>    --> Using cache 128aed2bca85f3f7f69200e80c2255bbc4b33f05d19e76bfdeeb1ef1bd747dea
>    --> 128aed2bca85
>    STEP 4/8: RUN groupadd --gid 1234 bob &&     useradd --uid 1234 --gid 1234 -m bob
>    --> Using cache 4948703b25da0706a261f272679a09a78ac927162ee518b30d73c08d69f582d5
>    --> 4948703b25da
>    STEP 5/8: USER bob
>    --> ce90e59554f0
>    STEP 6/8: WORKDIR /home/bob
>    --> 66f494c0fcf5
>    STEP 7/8: copy demo/ /home/bob/
>    --> 86b0fbf749d6
>    STEP 8/8: CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
>    COMMIT my-jupyter-image:latest
>    --> abcecc965802
>    Successfully tagged localhost/my-jupyter-image:latest
>    abcecc965802583cfd8f0e98ae390c29d67847a529465ac90c07f424908a859f
> ```
>
>   while the second time:
>
>```
>    podman build . -f Dockerfile -t my-jupyter-image:latest
>    STEP 1/8: FROM fedora:42
>    STEP 2/8: RUN dnf update -y &&     dnf -y --setopt=install_weak_deps=False install     python3     python3-pip &&     dnf clean all -y &&     rm -rf /var/cache* &&     rm -rf /var/log/dnf.*
>    --> Using cache 8c7d26298d302c379af212f9ea93238360a5912607d43980b2dd2ba9938290a6
>    --> 8c7d26298d30
>    STEP 3/8: RUN pip3 install --no-cache-dir     jupyterlab     numpy     matplotlib
>    --> Using cache 128aed2bca85f3f7f69200e80c2255bbc4b33f05d19e76bfdeeb1ef1bd747dea
>    --> 128aed2bca85
>    STEP 4/8: RUN groupadd --gid 1234 bob &&     useradd --uid 1234 --gid 1234 -m bob
>    --> Using cache 4948703b25da0706a261f272679a09a78ac927162ee518b30d73c08d69f582d5
>    --> 4948703b25da
>    STEP 5/8: USER bob
>    --> Using cache ce90e59554f0e913ff9e8ccbf068ece5659e5649933d5e5a58755842d6bd97f1
>    --> ce90e59554f0
>    STEP 6/8: WORKDIR /home/bob
>    --> Using cache 66f494c0fcf526e419debb4285d92fc5655ecd1851cb0d2b38fc9b644f1859f8
>    --> 66f494c0fcf5
>    STEP 7/8: copy demo/ /home/bob/
>    --> Using cache 86b0fbf749d62aad7871b409588be4dc2db867d47ac507a1a10f1ac627590661
>    --> 86b0fbf749d6
>    STEP 8/8: CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
>    --> Using cache abcecc965802583cfd8f0e98ae390c29d67847a529465ac90c07f424908a859f
>    COMMIT my-jupyter-image:latest
>    --> abcecc965802
>    Successfully tagged localhost/my-jupyter-image:latest
>    abcecc965802583cfd8f0e98ae390c29d67847a529465ac90c07f424908a859f
>```
> Can you see the difference?

</details>

Now we can run our custom image with the same command as before:

```bash
podman run -p 8888:8888 \
        my-jupyter-image:latest
```

### 5-bis. How can I share my image with colleagues? Push it to a registry!

To share your image with others, you can push it to a container registry, like [Docker Hub](https://hub.docker.com/).
The first step is to create an account on Docker Hub, if you don't have one already.


Once you have an account, you can login into Docker Hub from the command line:
```bash
podman login docker.io
```
You will be prompted to enter your username and password used during the registration.


Before pushing the image, you need to tag it with your Docker Hub username. The tag should be in the format `<username>/<image_name>:<tag>`. For example, if your Docker Hub username is `myusername`, you can tag the image like this:

```bash
podman tag my-jupyter-image:latest docker.io/<your_dockerhub_username>/my-jupyter-image:latest
```

And finally, you can push the image to Docker Hub with the following command:

```bash
podman push docker.io/<your_dockerhub_username>/my-jupyter-image:latest
```

Now check your Docker Hub account, you should see the image there!

***Exercises:***
- Push also the same container with a different tag, e.g., `v0.0.1`
- Modify the Dockerfile to add `pandas` and remove the `COPY` direcrive, build a new image and push it overriding the `latest` tag and creating a new tag `v0.0.2**

## 6. How to inspect a container/image? Entrypoints and CMD

To write down a good Dockerfile, (and simplify the debugging of your containers** a simple, but extremely effective, approach is to launch a container in interactive mode, and inspect what is inside the container, and run the command that you want to run in the Dockerfile.

***How to do that?***

$\rightarrow$ It depends from the image you are using... many things may change according to the image you are using...

| Case | Description                                                                                                                                                                                                                                               | Command to use                                  | Example                                                                                                                           |
|------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| 1    | The image has `bash`, `sh`, or another shell as its `CMD`. Easiest case.                                                                                                                                                                                  | `podman run -it <image>`                        | [`fedora:42`](https://github.com/fedora-cloud/docker-brew-fedora/blob/83a2c0273cd8d9547c49ccfe78962cef90661081/x86_64/Dockerfile) |
| 2    | The image has a `CMD` that is **not** a shell. You need to override the `CMD`.                                                                                                                                                                            | `podman run -it <image> /bin/bash`              | [`python:3.13`](https://github.com/docker-library/python/blob/master/3.13/bookworm/Dockerfile)                                    |
| 3    | The image has an `ENTRYPOINT` that is **not** a shell. In this case, you also need to override the `ENTRYPOINT`. `podman run -it <image> /bin/bash` will not work because `/bin/bash` will be considered arguments for whatever the custom entrypoint is. | `podman run -it --entrypoint /bin/bash <image>` | [this container](../codes/02-introduction-to-container/custom-entrypoint.Dockerfile)                                              |


Note that approach `3.** is the most general one, and it will work in all the cases, so if you are not sure, use it!


---

**Repetita juvant!**

Let's get rid of everything and start again from scratch!

```bash
podman system prune -a
podman volume prune
podman image prune -a
```

And now try to repeat by yourself all the steps we have seen so far!
