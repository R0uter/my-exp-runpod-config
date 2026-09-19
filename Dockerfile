FROM ghcr.io/letechlead/orcabonsai-27b-serving@sha256:45ebd198fe02fd8f62b04bf728beee771221dbe26b6ce1533b7a90e7cd0ed3b2
COPY proxy.pl /proxy.pl
COPY lb-boot.sh /lb-boot.sh
USER root
RUN chmod +x /lb-boot.sh /proxy.pl
# ponytail: bake LB /ping router so console can strip start cmd
ENTRYPOINT ["/lb-boot.sh"]
