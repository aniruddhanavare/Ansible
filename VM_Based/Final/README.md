# A playbook for automating deployment of IBM Cloud resources in multizone environment

## Download and Install collection

ansible-galaxy collection install ibm.cloudcollection --force

### Execute playbook
To execute complete deployment , run the 'deployment.yml' playbook:

    ```
    ansible-playbook deployment.yml -v --extra-vars "provider=ibmcloud name_prefix=miq-auto provider_apikey=XXX region=us-east resource_group_name=manage-iq tag=manageiq-vm-based-deploy object_storage_name='Cloud Object Storage-manage-iq' object_storage_location=global object_storage_plan=lite bucket_storage_class=standard image_url='https://releases.manageiq.org/' source_image_name=manageiq-openstack-kasparov-1.qc2 image_dest=/tmp/ custom_image_os=red-7-amd64-byol vsi_profile=bx2-2x8 acl_tcp_source=0.0.0.0/0 acl_tcp_destination=0.0.0.0/0 tcp_min_port=1 tcp_max_port=65535 acl_all_source=0.0.0.0/0 acl_all_destination=0.0.0.0/0 total_ipv4_address_count=256 network_interface_name=eth0 security_group_rule_ip_address=XX.XX.XX.XX primary_zone=us-east-2 standby_zone=us-east-2 cfme_ssh_user=root cfme_default_root_pw=xxxxx cfme_new_root_pw=xxxxxxx cfme_db_user=root cfme_db_pass=xxxxxx timeout=20"
    ```



