# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
	region = "us-west-2"
}

data "aws_availability_zones" "all" {}

# -------------------------------------------------------------------------------
# CREATE A VPC
# -------------------------------------------------------------------------------

resource "aws_vpc" "terraform" {
	cidr_block = "10.0.0.0/16"
}

# -------------------------------------------------------------------------------
# CREATE A GATEWAY TO GRANT ACCESS TO THE INTERNET
# -------------------------------------------------------------------------------

resource "aws_internet_gateway" "terraform" {
	vpc_id = "${aws_vpc.terraform.id}"
}

# -------------------------------------------------------------------------------
# GRANT THE VPC ACCESS TO THE INTERNET
# -------------------------------------------------------------------------------

resource "aws_route" "internet_access" {
	route_table_id = "${aws_vpc.terraform.main_route_table_id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.terraform.id}"
}

# -------------------------------------------------------------------------------
# CREATE A SUBNETS TO LAUNCH THE INSTANCES
# -------------------------------------------------------------------------------

resource "aws_subnet" "terraform" {
	vpc_id = "${aws_vpc.terraform.id}"
	cidr_block = "10.0.16.0/20"
	availability_zone = "us-west-2a"
	#map_public_ip_on_launch = true
}

resource "aws_subnet" "backterraform" {
	vpc_id = "${aws_vpc.terraform.id}"
	availability_zone = "us-west-2b"
	cidr_block = "10.0.32.0/20"
	#map_public_ip_on_launch = true
}

# -------------------------------------------------------------------------------
# CREATE THE AUTO SCALING GROUP
# -------------------------------------------------------------------------------

resource "aws_autoscaling_group" "example" {
	launch_configuration = "${aws_launch_configuration.webserver.id}"
	#availability_zones = ["us-west-2a", "us-west-2b"]
	vpc_zone_identifier = ["${aws_subnet.terraform.id}", "${aws_subnet.backterraform.id}"]
	load_balancers = ["${aws_elb.terraform.id}"]
	
	min_size = 1
	max_size = 5
	health_check_grace_period = 300
	health_check_type = "ELB"
	desired_capacity = 1

	tag{
		key = "Name"
		value = "WebServer"
		propagate_at_launch = true
	}
}

# -------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO THE WEB SERVER
# -------------------------------------------------------------------------------

resource "aws_security_group" "instance" {
	name = "terraform-example-instance"
	vpc_id = "${aws_vpc.terraform.id}"
		
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["10.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

# -------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO THE APP SERVER
# -------------------------------------------------------------------------------

resource "aws_security_group" "appserver" {
	name = "terraform-example-appserver"
	vpc_id = "${aws_vpc.terraform.id}"
	
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 9043
		to_port = 9043
		protocol = "tcp"
		cidr_blocks = ["10.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

# -------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO THE RDS SERVER
# -------------------------------------------------------------------------------

resource "aws_security_group" "rdsserver" {
	name = "terraform-example-rdsserver"
	vpc_id = "${aws_vpc.terraform.id}"
	
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 9043
		to_port = 9043
		protocol = "tcp"
		cidr_blocks = ["10.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

# -------------------------------------------------------------------------------
# CREATE A LAUNCH CONFIGURATION THAT DEFINES INSTANCE IN THE ASG FOR THE WEB SERVER
# -------------------------------------------------------------------------------

resource "aws_launch_configuration" "webserver" {
	image_id = "ami-e251209a"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.instance.id}"]
	
	name = "Web Server"
	
	user_data = <<-EOF
			#!/bin/bash
			yum update -y
            yum install -y httpd24 php56 mysql55-server php56-mysqlnd
            service httpd start
            chkconfig httpd on
			groupadd www
            usermod -a -G www ec2-user
            chown -R root:www /var/www
            chmod 2775 /var/www\n"
			find /var/www -type d -exec chmod 2775 {} +
            find /var/www -type f -exec chmod 0664 {} +
			EOF
	
	lifecycle {
		create_before_destroy = true
	}
}

# -------------------------------------------------------------------------------
# CREATE A APP SERVER
# -------------------------------------------------------------------------------

resource "aws_instance" "appserver" {
	ami = "ami-e251209a"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.appserver.id}"]
	subnet_id = "${aws_subnet.terraform.id}"
	availability_zone = "us-west-2a"
		
	tags {
		Name = "App Server"
	}
	lifecycle {
		create_before_destroy = true
	}
}	

# -------------------------------------------------------------------------------
# CREATE A DB SUBNET GROUP
# -------------------------------------------------------------------------------

resource "aws_db_subnet_group" "terraform" {
	name = "rdssubnet"
	subnet_ids = ["${aws_subnet.terraform.id}", "${aws_subnet.backterraform.id}"]
}

# -------------------------------------------------------------------------------
# CREATE A RDS SERVER
# -------------------------------------------------------------------------------

resource "aws_db_instance" "rdsserver" {
	allocated_storage = 10
	db_subnet_group_name = "${aws_db_subnet_group.terraform.id}"
	engine	= "postgres"
	engine_version = "9.5.4"
	instance_class = "db.t2.micro"
	name = "RDSServer"
	#parameter_group_name = "RDSparametergroup" 
	vpc_security_group_ids = ["${aws_security_group.rdsserver.id}"]
	password = "password"
	username = "rdsserver"
	skip_final_snapshot = true
		
	lifecycle {
		create_before_destroy = true
	}
}	
	
# -------------------------------------------------------------------------------
# CREATE AN ELB TO ROUTE TRAFFIC ACROSS THE AUTO SCALING GROUP
# -------------------------------------------------------------------------------

resource "aws_elb" "terraform" {
	name = "terraform-asg-example"
	#security_groups = ["${aws_security_group.elb.id}"]
	#availability_zones = ["us-west-2b", "us-west-2a"]
	subnets = ["${aws_subnet.terraform.id}","${aws_subnet.backterraform.id}"]
	cross_zone_load_balancing = true
	
	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 3
		timeout = 5
		interval = 30
		target = "http:${var.server_port}/"
	}

	listener {
		lb_port = 80
		lb_protocol = "http"
        instance_port = "80"
		instance_protocol = "http"
	}
}

# -------------------------------------------------------------------------------
#CREATE A SECURITY GROUP THAT CONTROLS WHAT TRAFFIC AN GO IN AND OUT OF THE ELB
# -------------------------------------------------------------------------------

resource "aws_security_group" "elb" {
    name = "terraform-example-elb"
	vpc_id = "${aws_vpc.terraform.id}"
    
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
    egress {
        from_port = 0  
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	
}
