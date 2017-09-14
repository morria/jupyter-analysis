FROM jupyter/all-spark-notebook
MAINTAINER Andrew S. Morrison "asm@collapse.io"

# Similar work here:
# https://github.com/boechat107/ext-spark-notebook/blob/master/Dockerfile#L34
#
# Discussion of SPARK_OPTS:
# https://github.com/jupyter/docker-stacks/issues/169

# Set up the environment
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update; apt-get -y upgrade; apt-get -y autoclean
RUN apt-get -y install git curl
RUN mkdir -p /usr/local/share/java
WORKDIR /tmp/
USER $NB_USER

# Upgrade Pandas
RUN pip install --upgrade pandas

# Matplotlib
COPY content/matplotlib.stylelib/asm.mplstyle /home/jovyan/.config/matplotlib/stylelib

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
    cp lib/opennlp-tools-1.5.3.jar /usr/local/share/java/opennlp-tools-1.5.0.jar; \
    cd .. ; rm -rf apache-opennlp*
USER $NB_USER
ENV SPARK_OPTS_JARS $SPARK_OPTS_JARS,/usr/local/share/java/opennlp-maxent-3.0.3.jar,/usr/local/share/java/opennlp-tools-1.5.3.jar,/usr/local/share/java/opennlp-uima-1.5.3.jar
ENV SPARK_CLASSPATH $SPARK_CLASSPATH:/usr/local/share/java/opennlp-maxent-3.0.3.jar:/usr/local/share/java/opennlp-tools-1.5.3.jar:/usr/local/share/java/opennlp-uima-1.5.3.jar

# Scala
USER $NB_USER
RUN curl -O https://raw.githubusercontent.com/alexarchambault/jupyter-scala/master/jupyter-scala
RUN chmod +x ./jupyter-scala
RUN ./jupyter-scala
USER $NB_USER

# PHP
# USER root
# RUN apt-get -y install php7.0 php7.0-cli php7.0-common php7.0-curl php7.0-opcache
# RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
# RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
# RUN php composer-setup.php
# RUN php -r "unlink('composer-setup.php');"
# RUN mv composer.phar /usr/local/bin/composer
# RUN curl -O https://litipk.github.io/Jupyter-PHP-Installer/dist/jupyter-php-installer.phar
# RUN php ./jupyter-php-installer.phar install
# USER $NB_USER


# Tensor Flow
USER root
RUN yes y | conda create -n tensorflow
RUN /bin/bash -c "source activate tensorflow"
RUN pip install --ignore-installed --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.3.0-cp36-cp36m-linux_x86_64.whl
USER $NB_USER


ENV TOREE_OPTS $TOREE_OPTS --jars $SPARK_OPTS_JARS
ENV SPARK_OPTS $SPARK_OPTS --jars $SPARK_OPTS_JARS

# Reset the environment
