FROM jupyter/all-spark-notebook
MAINTAINER Andrew S. Morrison "asm@trapezoid.work"

# Similar work here:
# https://github.com/boechat107/ext-spark-notebook/blob/master/Dockerfile#L34
#
# Discussion of SPARK_OPTS:
# https://github.com/jupyter/docker-stacks/issues/169


USER root


# Set up the environment
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update; apt-get -y upgrade; apt-get -y autoclean
RUN apt-get -y install git curl
RUN mkdir -p /usr/local/share/java
WORKDIR /tmp/

# NTLK
RUN pip install nltk

# Wordnet
RUN apt-get -y install wordnet wordnet-dev wordnet-sense-index
ADD http://downloads.sourceforge.net/project/jwordnet/jwnl/JWNL%201.4/jwnl14-rc2.zip jwnl14-rc2.zip
RUN unzip jwnl14-rc2.zip; cd jwnl14-rc2; \
    cp jwnl.jar /usr/local/share/java/; \
    chmod 755 /usr/local/share/java/jwnl.jar; \
    cd ..; rm -rf jwnl*
ENV SPARK_OPTS_JARS $SPARK_OPTS_JARS,/usr/local/share/java/jwnl.jar
ENV SPARK_CLASSPATH $SPARK_CLASSPATH:/usr/local/share/java/jwnl.jar

# OpenNLP
# ADD http://www-us.apache.org/dist/opennlp/opennlp-1.5.3/apache-opennlp-1.5.3-bin.tar.gz apache-opennlp-1.5.3-bin.tar.gz
# RUN tar -zxf apache-opennlp-1.5.3-bin.tar.gz ;\
#     cd apache-opennlp-1.5.3; \
#     cp lib/*.jar /usr/local/share/java/; \
#     cp lib/opennlp-tools-1.5.3.jar /usr/local/share/java/opennlp-tools-1.5.0.jar; \
#     cd .. ; rm -rf apache-opennlp*
# ENV SPARK_OPTS_JARS $SPARK_OPTS_JARS,/usr/local/share/java/opennlp-maxent-3.0.3.jar,/usr/local/share/java/opennlp-tools-1.5.3.jar,/usr/local/share/java/opennlp-uima-1.5.3.jar
# ENV SPARK_CLASSPATH $SPARK_CLASSPATH:/usr/local/share/java/opennlp-maxent-3.0.3.jar:/usr/local/share/java/opennlp-tools-1.5.3.jar:/usr/local/share/java/opennlp-uima-1.5.3.jar

# Graphviz
RUN apt-get -y install graphviz


USER $NB_USER


# Graphviz
RUN pip install graphviz
RUN pip install nxpd

# Upgrade Pandas
RUN pip install --upgrade pandas

# Tensor Flow
# RUN yes y | conda create -n tensorflow
# RUN /bin/bash -c "source activate tensorflow"
# RUN pip install --ignore-installed --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.3.0-cp36-cp36m-linux_x86_64.whl


# Matplotlib
COPY content/matplotlib.stylelib/asm.mplstyle /home/jovyan/.config/matplotlib/stylelib/asm.mplstyle

## Installing jupyter-vim-binding
## https://github.com/lambdalisue/jupyter-vim-binding
RUN mkdir -p $(jupyter --data-dir)/nbextensions && \
    cd $(jupyter --data-dir)/nbextensions && \
    git clone https://github.com/lambdalisue/jupyter-vim-binding.git vim_binding

# BASH kernel
RUN pip install bash_kernel
RUN python -m bash_kernel.install

# Scala
RUN curl -Lo coursier https://git.io/coursier-cli
RUN chmod +x coursier
RUN ./coursier launch --fork almond -- --install
RUN rm -f coursier

ENV TOREE_OPTS $TOREE_OPTS --jars $SPARK_OPTS_JARS
ENV SPARK_OPTS $SPARK_OPTS --jars $SPARK_OPTS_JARS

# Reset the environment
WORKDIR /home/jovyan
USER $NB_USER
