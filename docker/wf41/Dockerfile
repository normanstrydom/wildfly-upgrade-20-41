FROM quay.io/wildfly/wildfly:41.0.1.Final-jdk21

USER jboss
COPY apps/wf41-app.war /opt/jboss/wildfly/wf41-app.war
COPY docker/wf41/setup-wf41.cli /opt/jboss/wildfly/setup-wf41.cli

# Add admin user and configure domain mode with HA profile and port-offset 100
RUN /opt/jboss/wildfly/bin/add-user.sh -u admin -p "Admin123!" --silent && \
    /opt/jboss/wildfly/bin/jboss-cli.sh --file=/opt/jboss/wildfly/setup-wf41.cli && \
    rm -f /opt/jboss/wildfly/setup-wf41.cli /opt/jboss/wildfly/wf41-app.war

EXPOSE 8180 8543 10090

CMD ["/opt/jboss/wildfly/bin/domain.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0", "-Djboss.management.http.port=10090"]
