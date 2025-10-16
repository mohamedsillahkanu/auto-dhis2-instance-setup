FROM tomcat:9.0-jdk17-temurin    

# Set environment variables
ENV CATALINA_OPTS="-Xms1024m -Xmx2048m -XX:+UseG1GC"
ENV DHIS2_HOME=/opt/dhis2

# Install required packages
RUN apt-get update && \
    apt-get install -y wget && \
    apt-get clean

# Create DHIS2 directories
RUN mkdir -p /opt/dhis2/files && \
    chown -R root:root /opt/dhis2

# Download DHIS2 WAR file
RUN wget -O /usr/local/tomcat/webapps/ROOT.war \
    https://releases.dhis2.org/2.40/dhis2-stable-2.40.5.war

# Copy configuration file
COPY dhis.conf /opt/dhis2/dhis.conf

# Set proper permissions
RUN chmod 600 /opt/dhis2/dhis.conf

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
