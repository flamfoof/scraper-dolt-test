FROM continuumio/anaconda3

WORKDIR /app

RUN apt-get update\
    && apt-get install -y wine
RUN apt-get update \
    && apt-get install -y build-essential 

COPY requirements.txt ./
RUN pip install -r ./requirements.txt
# COPY conda_requirements.txt ./
# RUN conda install --file ./conda_requirements.txt

RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y unzip \
    && curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

RUN apt-get update \
    && wget https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_123.0.6312.86-1_amd64.deb \
    && apt install -y ./google-chrome*.deb \
    && rm -rf ./google-chrome*.deb

RUN apt-get update \
    && mkdir ./temp/ \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "./temp/awscliv2.zip" \
    && cd ./temp/ \
    && unzip awscliv2.zip \
    && ./aws/install

RUN npm install -g bun
RUN bun install libsql
RUN bun install puppeteer -g
RUN bunx @puppeteer/browsers install chrome@123
RUN bunx @puppeteer/browsers install chromedriver@123

COPY package.json ./
COPY package-lock.json ./
RUN npm install

COPY ./main.sh .
COPY . .

RUN find . -type f -name "*.sh" -exec chmod +x {} \;

CMD bash ./main.sh