#!/bin/bash
# EC2 user data: installs Apache and publishes a small demo storefront.
dnf update -y
dnf install -y httpd
systemctl enable --now httpd

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Demo Store | Africa &amp; Asia</title>
  <style>
    body{font-family:system-ui,sans-serif;margin:0;background:#f6f7f9;color:#1c2430}
    header{background:#0b3d5c;color:#fff;padding:2rem 1rem;text-align:center}
    main{max-width:880px;margin:2rem auto;padding:0 1rem;display:grid;gap:1rem;grid-template-columns:repeat(auto-fit,minmax(200px,1fr))}
    .card{background:#fff;border-radius:10px;padding:1.2rem;box-shadow:0 1px 4px rgba(0,0,0,.08)}
    footer{text-align:center;color:#667;font-size:.85rem;padding:2rem}
  </style>
</head>
<body>
  <header><h1>Demo Store</h1><p>Available to customers in Africa and Asia</p></header>
  <main>
    <div class="card"><h3>Kitenge Tote</h3><p>USD 18</p></div>
    <div class="card"><h3>Handwoven Basket</h3><p>USD 25</p></div>
    <div class="card"><h3>Silk Scarf</h3><p>USD 32</p></div>
  </main>
  <footer>Served from EC2 in $AZ through Amazon CloudFront</footer>
</body>
</html>
EOF
