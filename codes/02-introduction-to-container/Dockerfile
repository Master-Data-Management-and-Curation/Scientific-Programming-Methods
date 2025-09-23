FROM fedora:42

RUN dnf update -y && \
    dnf -y --setopt=install_weak_deps=False install \
    python3 \
    python3-pip && \
    dnf clean all -y && \
    rm -rf /var/cache* && \
    rm -rf /var/log/dnf.*

RUN pip3 install --no-cache-dir \
    jupyterlab \
    numpy \
    matplotlib

RUN groupadd --gid 1234 bob && \
    useradd --uid 1234 --gid 1234 -m bob

USER bob

WORKDIR /home/bob

copy demo/ /home/bob/

# Leave the default ENTRYPOINT of the image: /bin/bash -c
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
