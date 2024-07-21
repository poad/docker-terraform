FROM buildpack-deps:stable-curl AS downloader

ARG TARGETPLATFORM

RUN PLATFORM=$( \
      case ${TARGETPLATFORM} in \
        linux/amd64 ) echo "amd64";; \
        linux/arm64 ) echo "arm64";; \
      esac \
    ) \
 && curl -sSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/1.9.2/terraform_1.9.2_linux_${PLATFORM}.zip" \
 && curl -sSLo /tmp/InstallAzureCLIDeb https://aka.ms/InstallAzureCLIDeb

FROM buildpack-deps:noble-curl

COPY --from=downloader /tmp/terraform.zip /tmp/terraform.zip
COPY --from=downloader /tmp/InstallAzureCLIDeb /tmp/InstallAzureCLIDeb

WORKDIR /tmp

RUN chmod +x /tmp/InstallAzureCLIDeb \
 && /tmp/InstallAzureCLIDeb \
 && rm -rf /tmp/InstallAzureCLIDeb

RUN mkdir -p /etc/apt/keyrings \
 && curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null \
 && chmod go+r /etc/apt/keyrings/microsoft.gpg

RUN echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list

RUN apt-get update -qqqqy \
  && apt-get install -qqqy --no-install-recommends unzip azure-cli \
  && unzip /tmp/terraform.zip \
  && rm -fr /tmp/terraform.zip \
  && mv terraform /usr/local/bin/ \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/apt/* /var/log/alternatives.log /var/log/dpkg.log /var/log/faillog /var/log/lastlog

RUN groupadd -g 10000 terraform \
&& useradd -g 10000 -l -m -s /usr/bin/bash -u 10000 terraform


USER terraform

WORKDIR /home/terraform
