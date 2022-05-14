FROM drakkan/sftpgo:v2-alpine

EXPOSE 8080/tcp 2022/tcp

CMD ["sftpgo", "serve"]
