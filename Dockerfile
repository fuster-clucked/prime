FROM nimlang/nim

RUN apt-get install -y liblmdb0 lmdb-utils
RUN ln /usr/lib/x86_64-linux-gnu/liblmdb.so.0.0.0 /usr/lib/x86_64-linux-gnu/liblmdb.so

# build nimble from source
# since official container uses nimble v0.8.2
# which has issues displaying compiler messages

WORKDIR /root
RUN git clone https://github.com/nim-lang/nimble.git

WORKDIR /root/nimble
RUN nim c src/nimble
RUN src/nimble install -y
RUN rm /bin/nimble
RUN ln -s ~/.nimble/bin/nimble /bin/nimble

WORKDIR /
