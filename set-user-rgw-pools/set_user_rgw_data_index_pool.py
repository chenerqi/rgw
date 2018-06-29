import commands
import sys, os

if __name__ == "__main__":
    placement_target = sys.argv[1]
    pg_num = sys.argv[2]

    '''
    # delete default pool
    cmd = "rados lspools | grep .rgw.root"
    root_rgw_pool = commands.getoutput(cmd)
    print root_rgw_pool
    print len(root_rgw_pool)
    if root_rgw_pool == ".rgw.root":
        print "find"
    '''

    # delete root rgw pool
    pool = ".rgw.root"
    cmd = "rados lspools | grep %s" % (pool)
    status, result = commands.getstatusoutput(cmd)
    print status, result
    if status == 0:
        delete_pool_cmd = \
        "ceph osd pool delete %s %s --yes-i-really-really-mean-it" % (pool, pool)
        print delete_pool_cmd
        os.system(delete_pool_cmd)
    create_pool_cmd = \
    "ceph osd pool create %s %s %s replicated" % (pool, pg_num, pg_num)
    print create_pool_cmd
    os.system(create_pool_cmd)
    
    # delete default rgw pool
    cmd = "rados lspools | grep rgw | grep default"
    status, result = commands.getstatusoutput(cmd)
    print status, result
    if status == 0:
       pools = result.split('\n')
       print pools
       for pool in pools:
            delete_pool_cmd = \
            "ceph osd pool delete %s %s --yes-i-really-really-mean-it" % (pool, pool)
            print delete_pool_cmd
            os.system(delete_pool_cmd)

    # create user rgw pools
    with open("user_rgw_pool.txt", "r") as f:
        lines = f.readlines()
        for line in lines:
            line = line.strip()
            pool = "%s%s" % (placement_target, line)
            # delete if the pool exists
            cmd = "rados lspools | grep %s" % (pool)
            status, result = commands.getstatusoutput(cmd)
            print status, result
            if status == 0:
                delete_pool_cmd = \
                "ceph osd pool delete %s %s --yes-i-really-really-mean-it" % (pool, pool)
                print delete_pool_cmd
                os.system(delete_pool_cmd)
            if "index" in pool: 
            	create_pool_cmd = \
                   "ceph osd pool create %s %s %s replicated index_ruleset" % (pool, pg_num, pg_num)
            else:
		create_pool_cmd = \
                   "ceph osd pool create %s %s %s replicated data_ruleset" % (pool, pg_num, pg_num)

            print create_pool_cmd
            os.system(create_pool_cmd)

    # create realm, zonegroup, zone, placement, and set new placement to default
    with open("user_rgw_realm.txt", "r") as f:
        lines = f.readlines()
        for line in lines:
            cmd = line.strip()
            print cmd
            os.system(cmd)
