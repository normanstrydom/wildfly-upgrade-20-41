FROM jboss/wildfly:20.0.1.Final

USER jboss
COPY setup-lb.cli /opt/jboss/wildfly/setup-lb.cli

# Pre-configure Undertow reverse-proxy as ingress load balancer
RUN /opt/jboss/wildfly/bin/add-user.sh -u admin -p "Admin123!" --silent && \
    /opt/jboss/wildfly/bin/jboss-cli.sh --file=/opt/jboss/wildfly/setup-lb.cli && \
    rm -f /opt/jboss/wildfly/setup-lb.cli

EXPOSE 8080 9990

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
