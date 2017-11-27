require_relative 'git2cw'

git2cw = Git2CW.new
git2cw.check_new_event
git2cw.shutdown
