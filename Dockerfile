FROM jupyter/all-spark-notebook
MAINTAINER Andrew S. Morrison "asm@collapse.io"


# Set up the environment
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update; apt-get -y upgrade; apt-get -y autoclean
RUN apt-get -y install git
RUN mkdir -p /usr/local/share/java
WORKDIR /tmp/
USER $NB_USER

## Installing jupyter-vim-binding
## https://github.com/lambdalisue/jupyter-vim-binding
RUN mkdir -p $(jupyter --data-dir)/nbextensions && \
    cd $(jupyter --data-dir)/nbextensions && \
    git clone https://github.com/lambdalisue/jupyter-vim-binding.git vim_binding

# NTLK
USER root
RUN pip install nltk
USER $NB_USER

# BASH kernel
RUN pip install bash_kernel
RUN python -m bash_kernel.install

# Wordnet
USER root
RUN apt-get -y install wordnet wordnet-dev wordnet-sense-index
ADD http://downloads.sourceforge.net/project/jwordnet/jwnl/JWNL%201.4/jwnl14-rc2.zip jwnl14-rc2.zip
RUN unzip jwnl14-rc2.zip; cd jwnl14-rc2; \
    cp jwnl.jar /usr/local/share/java/; \
    chmod 755 /usr/local/share/java/jwnl.jar; \
    cd ..; rm -rf jwnl*
USER $NB_USER
ENV SPARK_OPTS_JARS $SPARK_OPTS_JARS,/usr/local/share/java/jwnl.jar
ENV SPARK_CLASSPATH $SPARK_CLASSPATH:/usr/local/share/java/jwnl.jar

# OpenNLP
USER root
ADD http://www-us.apache.org/dist/opennlp/opennlp-1.5.3/apache-opennlp-1.5.3-bin.tar.gz apache-opennlp-1.5.3-bin.tar.gz
RUN tar -zxf apache-opennlp-1.5.3-bin.tar.gz ;\
    cd apache-opennlp-1.5.3; \
    cp lib/*.jar /usr/local/share/java/; \
    cp lib/*.jar /usr/share/java/; \
    cp lib/opennlp-tools-1.5.3.jar /usr/local/share/java/opennlp-tools-1.5.0.jar; \
    cd .. ; rm -rf apache-opennlp*
USER $NB_USER
ENV SPARK_OPTS_JARS $SPARK_OPTS_JARS,/usr/local/share/java/opennlp-tools-1.5.3.jar
ENV SPARK_CLASSPATH $SPARK_CLASSPATH:/usr/local/share/java/opennlp-tools-1.5.3.jar

# Scala
# RUN curl -O https://oss.sonatype.org/content/repositories/snapshots/sh/jove/jove-scala-cli_2.11/0.1.1-1-SNAPSHOT/jove-scala-cli_2.11-0.1.1-1-SNAPSHOT.tar.gz
# RUN tar xzf jove-scala-cli_2.11-0.1.1-1-SNAPSHOT.tar.gz
# RUN cd jove-scala-cli-0.1.1-1-SNAPSHOT/; \
#     ./bin/jove-scala --kernel-spec;

ENV TOREE_OPTS $TOREE_OPTS --jars $SPARK_OPTS_JARS
ENV SPARK_OPTS $SPARK_OPTS --jars $SPARK_OPTS_JARS

# Reset the environment
WORKDIR /home/jovyan
USER $NB_USER
