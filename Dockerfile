FROM openshift/base-centos7

MAINTAINER Ricardo Martinelli de Oliveira <rmartine@redhat.com>

ENV JETTY_HOME /usr/local/jetty
RUN mkdir -p "$JETTY_HOME"
WORKDIR $JETTY_HOME

ENV JETTY_VERSION 9.3.5.v20151012
ENV JETTY_BASE /var/lib/jetty
ENV JETTY_RUN /run/jetty
ENV JETTY_STATE $JETTY_RUN/jetty.state
ENV TMPDIR /tmp/jetty

# Agent bond including Jolokia and jmx_exporter
ADD agent-bond-opts /opt/run-java-options
RUN mkdir -p /opt/agent-bond \
 && curl http://central.maven.org/maven2/io/fabric8/agent-bond-agent/1.2.0/agent-bond-agent-1.2.0.jar \
          -o /opt/agent-bond/agent-bond.jar \
 && chmod 444 /opt/agent-bond/agent-bond.jar \
 && chmod 755 /opt/run-java-options
ADD jmx_exporter_config.yml /opt/agent-bond/
EXPOSE 8778 9779

RUN set -xe \
	&& curl -SL "https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz" -o jetty.tar.gz \
	&& tar -xvf jetty.tar.gz --strip-components=1 \
	&& sed -i '/jetty-logging/d' etc/jetty.conf \
	&& rm -fr demo-base javadoc \
	&& rm jetty.tar.gz* \
	&& mkdir -p "$JETTY_BASE" \
	&& mkdir -p "$JETTY_RUN" "$TMPDIR" \
	&& chmod -R og+rw "$JETTY_HOME" "$JETTY_RUN" "$TMPDIR" \
        && chown -R 1001:1001 "$JETTY_RUN" "$TMPDIR" "$JETTY_BASE" \
	&& yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel \
	&& (curl -0 http://www.us.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz | tar -zx -C /usr/local) \
  && ln -sf /usr/local/apache-maven-3.3.3/bin/mvn /usr/local/bin/mvn \
	&& yum clean all -y
	#&& modules="$(grep -- ^--module= "$JETTY_HOME/start.ini" | cut -d= -f2 | paste -d, -s)" \
  #&& java -jar "$JETTY_HOME/start.jar" --add-to-startd="$modules,setuid"
ADD jetty-logging.xml /opt/jetty/etc/ 
COPY run-java.sh /opt/
RUN chmod 755 /opt/run-java.sh

# TODO: Set labels used in OpenShift to describe the builder image
#LABEL io.k8s.description="Platform for building xyz" \
#      io.k8s.display-name="builder x.y.z" \
#      io.openshift.expose-services="8080:http" \
#      io.openshift.tags="builder,x.y.z,etc."
LABEL io.openshift.s2i.scripts-url=image:///usr/local/sti
LABEL io.s2i.scripts-url=image:///usr/local/sti

# TODO: Copy the S2I scripts to /usr/local/sti, since openshift/base-centos7 image sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./.sti/bin/ /usr/local/sti

# This default user is created in the openshift/base-centos7 image
USER 1001

EXPOSE 8080
CMD ["usage"]
