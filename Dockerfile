FROM alpine:3.6
EXPOSE 9000

RUN apk add --no-cache ca-certificates && update-ca-certificates
ADD vattenfall /bin/

ENTRYPOINT ["/bin/vattenfall"]