# Part 3+ — container for CI build / ECS (nginx serves /healthz on :80)
FROM nginx:1.27-alpine

COPY app/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
