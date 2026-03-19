typebuild:
	cd packages/shared && pnpm build

start:
	cd apps/db && supabase start

stop:
	cd apps/db && supabase stop

# dbcheck:
# 	docker container ps
#
# dbstart:
# 	supabase start
#
# dbstop:
# 	supabase stop
#
#
