FROM jboss/wildfly:20.0.1.Final

USER jboss
COPY apps/wf20-app.war /opt/jboss/wildfly/wf20-app.war
COPY docker/wf20/setup-wf20.cli /opt/jboss/wildfly/setup-wf20.cli
COPY docker/wf20/route-to-wf41.cli /opt/jboss/wildfly/route-to-wf41.cli
COPY docker/wf20/rollback-route.cli /opt/jboss/wildfly/rollback-route.cli

# Add admin user and configure domain mode with HA profile and deployments
RUN /opt/jboss/wildfly/bin/add-user.sh -u admin -p "Admin123!" --silent && \
    /opt/jboss/wildfly/bin/jboss-cli.sh --file=/opt/jboss/wildfly/setup-wf20.cli && \
    rm -f /opt/jboss/wildfly/setup-wf20.cli /opt/jboss/wildfly/wf20-app.war

EXPOSE 8080 8443 9990

CMD ["/opt/jboss/wildfly/bin/domain.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
