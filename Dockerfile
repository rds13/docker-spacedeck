FROM ubuntu:16.04

WORKDIR /app

# build audiowaveform from source

RUN apt-get update
RUN apt-get install -y git make cmake gcc g++ wget curl \
  libmad0-dev libid3tag0-dev libsndfile1-dev libgd-dev \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-regex-dev
#
RUN apt-get install -y autoconf automake libtool-bin gettext pkg-config
RUN wget https://github.com/xiph/flac/archive/1.3.3.tar.gz
RUN tar xzf 1.3.3.tar.gz
RUN cd flac-1.3.3/ && ./autogen.sh
RUN cd flac-1.3.3/ && ./configure --enable-shared=no
RUN cd flac-1.3.3/ && make
RUN cd flac-1.3.3/ && make install
#
RUN git clone https://github.com/bbc/audiowaveform.git
RUN mkdir audiowaveform/build/
RUN cd audiowaveform/build/ && cmake -D ENABLE_TESTS=0 -D BUILD_STATIC=1 ..
RUN cd audiowaveform/build/ && make
RUN cd audiowaveform/build/ && make install
#
## install chromium
RUN apt-get install -y \
    chromium-browser \
    libfreetype6 \
    libfreetype6-dev \
    ca-certificates \
    ttf-freefont
#
## Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
#
## install other requirements
#
RUN apt-get install -y graphicsmagick ffmpeg ghostscript
#
# Do some cleanup
RUN \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install node package
RUN mkdir /app/nvm
ENV NVM_DIR /app/nvm
ENV NODE_VERSION 10.24.1

RUN curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh -o install_nvm.sh
RUN chmod 755 ./install_nvm.sh && ./install_nvm.sh

RUN . "$NVM_DIR/nvm.sh" \
  &&  nvm install $NODE_VERSION \
  &&  nvm alias default $NODE_VERSION \
  &&  nvm use default

ENV PATH  $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
COPY package*.json ./
RUN npm install
COPY . .

# start app
EXPOSE 9666
CMD ["node", "spacedeck.js"]
