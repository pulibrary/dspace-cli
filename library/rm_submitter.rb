#!/usr/bin/env jruby
require 'dspace'
require "highline/import"

DSpace.load()
DSpace.context_renew

name = "Lib_DigPubs_Submitters"
group = DGroup.find(name)

while (true) do
  netid = ask "Netid of person to remove / or blank to exit> "
  if (netid != "") then
    m = DEPerson.find(netid)
    if (m) then
        puts ['removing', name, m.getEmail, m.canLogIn ? "Can Login" : "can't Login", m.getFullName].join "\t\t"
        group.removeMember(m)
    else
      puts "no such eperson"
    end
  else
    break
  end
end

yes = ask "Commit ? (Y/N)"
if (yes[0] == 'Y') then
    DSpace.login(ENV['USER'])
    group.update()
    DSpace.commit
end








