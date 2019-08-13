======================== THIS IS A README FILE =====================

This project consist of installing a simple web server (httpd) in a public subnet connected to an RDS instance (MySQL DB instance) in a private subnet. We will do this in AWS.

To have a highly available web server, i created a custom VPC (in eu-west-1) with two public subnet and two private subnet. The ec2 instance hosting the web server is in an autoscaling group with a desired capacity of one that would scale on a threshhold of over 70% of CPU utilization. Also for making the RDS instance highly available and fault tolerant, i installed the DB instance using Multi-AZ deployments.

For security, i created a public security group that allow traffic for HTTP(80) from internet, SSH(22) from a given subnet in my corporate network and a RDS security group that allow traffic for MySQL(3306) from only the public subnets in my custom VPC.

I used terrafomr for providing all those services described here and many more.

I created a s3 bucket as a backend to store the state and keep tracking changes made in my infrastructure.

I also created a pipiline in Gitlab to automate the build, test, and deploy process (based on configuration in file .gitlab-ci.yml)
