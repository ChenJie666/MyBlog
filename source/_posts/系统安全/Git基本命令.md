---
title: Git基本命令
categories:
- 系统安全
---
# 一、Git登录设置
## 1.1 Git设置秘钥ssh登录，这样在推送和拉去代码时可以免去输入账号密码：
1. 打开Git Bash Here
2. ssh-keygen -t rsa -C 'cj21' 创建公私钥，默认保存在当前用户下的.ssh文件夹中
3. 将id_rsa.pub中的内容粘贴到gitee中的SSH公钥中完成配置。
如果是Github，则点击 settings -> SSH and GPG keys -> New SSH key 将公钥粘贴进去并创建。
如果需要销毁该公钥，则点击 settings -> Account secutiry -> Sessions ，找到目标公钥并删除即可。

## 1.2 Git使用token登录
因为某些原因，使用账号密码登录失败，可以使用token进行登录。
1. 点击 Settings -> Developer settings ->  Generate a personal access token 创建token

<br>
# 二、文件同步
初始化 用户信息
`git config --global user.name CJ`
`git config --global user.email chenjie.sg@outlook.com`
查看信息
`git config --global --list`

## 2.1 Git推送本地文件
```
$ git init     #初始化当前文件
$ git add .     #将本地文件添加到待提交目录(不包括删除操作)
$ git status    #查看添加的文件状态
$ git diff         #查看工作区的文件修改
$ git diff --cached  #查看暂存区的文件修改
$ git commit -m '提交文件'      #将待提交目录中的文件提交本地仓库
$ git log -g  # 查看历史commit记录
$ git show [commitId]  #通过查看commitId可以看到修改的内容
$ git commit --amend -m 'message'   #修改最近一次提交的说明信息
$ git remote add origin [你的远程库地址]      #关联到远程库
$ git push -u origin master     #当前分支推送到远程仓库的master分支
$ git push origin chenjie:chenjie  #推送到指定分支(将本地chenjie分支推送到远程origin地址的chenjie分支上)
```
注：
```
$git status    #查看文件状态(标红的为修改的文件)
$git add -u      #提交被修改和删除的文件，不含添加的文件
$git add -A      #提交所有的变化
```

>git remote show 查看远程地址
>git remote rm origin 删除远程地址
>git remote add origin xxxxx.git 添加远程地址

## 2.2 复制原分支代码到新分支
1、切换到原分支
```
$ git checkout oldBranch
$ git pull
```
2、从原分支复制到新分支
```
$ git checkout -b newBranch
```
3、将新分支的代码推送到远程服务器
```
$ git push origin newBranch
```
4、拉取远程分支的代码
```
$ git pull
```
5、关联
```
$git branch --set-upstream-to=origin/newBranch
```
6、再次拉取代码
```
$ git pull
```

## 2.3 拉取指定分支的远程仓库代码
```
git clone -b develop XXX 
```

## 2.4 github中的教程
**create a new repository on the command line**
```
echo "# FineDB_Bigdata_Script" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/ChenJie666/FineDB_Bigdata_Script.git
git push -u origin main
```

**push an existing repository from the command line**
```
git remote add origin https://github.com/ChenJie666/FineDB_Bigdata_Script.git
git branch -M main
git push -u origin main
```

## 2.5 合并prod分支到test分支
第一步：拉取分支
```
git clone https://xxxx
```
第二步：合并分支
```
git fetch origin
git checkout origin/test
git merge --no-ff prod
```
第三步：解决本地test分支中的冲突
将每个冲突的文件中的冲突解决
也可以放弃本次合并
```
git merge --abort
```
第四步：提交分支到test分支
```
git push origin test
```
>git merge会合并全部的文件，如果只想合并某些文件，可以使用命令`git checkout [branch] [filepath1] [filepath2] ...` 可以合并远程分支，如远程origin/master分支。如果想回滚暂存区的文件，可以使用`git checkout HEAD [filepath]`；如果想回滚到某一版本的文件，可以使用`git checkout [commitID] [filepath]`

<br>
# 三、Linux下Git保存用户密码
**Git使用store模式存储账号密码**
store模式，认证信息会被明文保存在一个本地文件中，并且没有过期限制。使用git命令需要认证的时候，就会自动从这里读取用户认证信息完成认证。创建步骤如下：
1. 用户目录下创建文件并编辑文件 `.git-credentials` 如下
```
https://{username}:{password}@github.com
```
>这里可以直接填写明文的账号密码。但是为了安全，这里的password一般并不是账户的密码，以Github为例，这里使用的是AccessToken（oauth2:access_token），可以在Settings-Developer Settings-Personal access tokens中生成新的密钥，然后配置git-credentials使用此密钥访问。
配置好credentials服务和密钥后，在其它使用git命令需要认证的时候，就会自动从这里读取用户认证信息完成认证了。

2. 在终端下执行 
`git config --global credential.helper store`

3. 可以看到~/.gitconfig文件，会多了一项：
   ```
   [credential]
   helper = store
   ```

当使用的目标地址匹配时，会自动使用该账号密码。


<br>
# 四、Git忽略规则(.gitignore配置)不生效原因和解决
## 4.1 第一种方法:
.gitignore中已经标明忽略的文件目录下的文件，git push的时候还会出现在push的目录中，或者用git status查看状态，想要忽略的文件还是显示被追踪状态。
原因是因为在git忽略目录中，新建的文件在git中会有缓存，如果某些文件已经被纳入了版本管理中，就算是在.gitignore中已经声明了忽略路径也是不起作用的，
这时候我们就应该先把本地缓存删除，然后再进行git的提交，这样就不会出现忽略的文件了。
  
解决方法: git清除本地缓存（改变成未track状态），然后再提交:
```
$ git rm -r --cached .
$ git add .
$ git commit -m 'update .gitignore'
$ git push -u origin master
```

>删除工作区的修改内容 `git checkout .`
删除缓存区的文件 `git rm -r --cached .`
删除本地仓库的文件 `git reset --soft [commitId]`

**需要特别注意的是：**
1）.gitignore只能忽略那些原来没有被track的文件，如果某些文件已经被纳入了版本管理中，则修改.gitignore是无效的。
2）想要.gitignore起作用，必须要在这些文件不在暂存区中才可以，.gitignore文件只是忽略没有被staged(cached)文件，
   对于已经被staged文件，加入ignore文件时一定要先从staged移除，才可以忽略。
 
## 4.2 第二种方法:（推荐）
在每个clone下来的仓库中手动设置不要检查特定文件的更改情况。
```
$ git update-index --assume-unchanged PATH    #在PATH处输入要忽略的文件
```

在使用.gitignore文件后如何删除远程仓库中以前上传的此类文件而保留本地文件
在使用git和github的时候，之前没有写.gitignore文件，就上传了一些没有必要的文件，在添加了.gitignore文件后，就想删除远程仓库中的文件却想保存本地的文件。这时候不可以直接使用"git rm directory"，这样会删除本地仓库的文件。可以使用"git rm -r –cached directory"来删除缓冲，然后进行"commit"和"push"，这样会发现远程仓库中的不必要文件就被删除了，以后可以直接使用"git add -A"来添加修改的内容，上传的文件就会受到.gitignore文件的内容约束。

额外说明：git库所在的文件夹中的文件大致有4种状态
| 状态 | 说明 |
| --- | --- |
| Untracked | 未跟踪, 此文件在文件夹中, 但并没有加入到git库, 不参与版本控制. 通过git add 状态变为Staged. |
| Unmodify | 文件已经入库, 未修改, 即版本库中的文件快照内容与文件夹中完全一致. 这种类型的文件有两种去处, 如果它被修改，而变为Modified. 如果使用git rm移出版本库, 则成为Untracked文件 |
| Modified | 文件已修改, 仅仅是修改, 并没有进行其他的操作. 这个文件也有两个去处, 通过git add可进入暂存staged状态,使用git checkout 则丢弃修改过, 返回到unmodify状态, 这个git checkout即从库中取出文件, 覆盖当前修改 |
| Staged | 暂存状态. 执行git commit则将修改同步到库中, 这时库中的文件和本地文件又变为一致, 文件为Unmodify状态. 执行git reset HEAD filename取消暂存, 文件状态为Modified |

 
Git 状态 untracked 和 not staged的区别
1）untrack     表示是新文件，没有被add过，是为跟踪的意思。
2）not staged  表示add过的文件，即跟踪文件，再次修改没有add，就是没有暂存的意思

>可以通过add/rm添加到git暂存区或从git暂存区删除文件。可以使用git restore [file] 来放弃工作区的修改。

<br>
## 五、 合并策略
**常规合并里分为三种:**
- 解决（Resolve）
- 递归（Recursive）
- 章鱼（Octopus）

**非常规两种:**
- 我们的（Ours）
- 子树（Subtree）


**策略详解**
- **解决（Resolve）**：
这种策略只能合并两个分支，首先定义某个次commit为祖先为合并基础，然后执行一个直接的三方合并
- **递归（Recursive）**：
和解决很相似，说白了就是多次的调用解决。为什么会有这个策略呢？因为解决策略，是找到两个分支的某个commit为组向才来合并的，如果某一个分支上，某一次提交（祖先或者祖先以后的提交）是merge过的，这时候，就需要递归来解决了。
- **章鱼（Octopus）**：
当需要多个分支的时候，就可以用octopus来解决，这就是来同时合并多个分支的策略。
- **我们的（Ours）**：
这是一个很奇怪的策略，我感觉没啥用，不知道其用途是如何
它的作用是，将另外一个分支的commit记录（log）提交过来，但是不提交文件本身。
- **子树（Subtree）**：
这种策略是在用于，当想将一个新的项目作为该项目的子项目往git上提交时可以使用，说白了就是将其当做一个子模块一般。

**merge在做处理时候的参数主要分为三种：**
```
--ff  --ff--only  快速合并    只快速合并（如果有冲突就失败）
--no-ff   非快速合并
--squash  将合并过来的分支的所有不同的提交，当做一次提交，提交过来

--ff和--no-ff的区别是，当解决完冲突后，no-ff会生成一次commit
eg: Merge branch 'suit' into master
```

<br>
## 六、实践
### 6.1 记一次Git上传失败
1. 使用 `git push -u origin test:test` 上传失败
```
$ git push -u origin test:test
To http://gitlab.iotmars.com/backend/compass/hxr_compass_jobscript.git
 ! [rejected]        test -> test (non-fast-forward)
error: failed to push some refs to 'http://gitlab.iotmars.com/backend/compass/hxr_compass_jobscript.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. Integrate the remote changes (e.g.
hint: 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```
原因就是远程代码发生没有合并。
2. 通过命令 git pull 拉取代码，也可以通过组合命令 `git fetch origin test;git merge origin FETCH_HEAD` 拉取代码
3. 注意显示的冲突文件，在本地文件中解决冲突。
4. 然后重新提交代码即可。

### 6.2 合并冲突分支
Step 1. Fetch and check out the branch for this merge request
```
git fetch origin
git checkout -b test origin/test
```
Step 2. Review the changes locally
Step 3. Merge the branch and fix any conflicts that come up
```
git fetch origin
git checkout origin/prod
git merge --no-ff test
git status #查看冲突状态
```
Step 4. Push the result of the merge to GitLab
```
git push origin prod
```

### 6.3 放弃本地修改，云端强制覆盖本地
```
$ git fetch --all
$ git reset --hard origin/master
$ git pull
```

git reset  就是当我们提交了错误的内容后进行回退使用的命令。
git reset [版本号]，就是回退到该版本号上。
通常我们使用git reset HEAD就是回退到当前版本。git reset HEAD^回退到上一版本

参数--hard，直接把工作区的内容也修改了，不加--hard的时候只是操作了暂存区，不影响工作区的，--hard一步到位(即同时操作了暂存区，也会将文件从云端还原到本地)，不加--hard需要分开执行reset和checkout。


如我们git add 一个文件，这时我们发现添加了错误的内容，此时我们只是做了add 操作，就是将修改了内容添加到了暂存区，还没有执行commit，所以还没有生成版本号，当前的版本号对应的内容，还是你add之前的内容，所以我们只需要将代码回退到当前版本就行，执行git reset HEAD，随后通过git status查看状态，可以发现回到了add前的状态。

如果希望修改的本地文件也进行还原，则执行 git checkout [文件名] ，拉取云端内容同步到本地。

### 6.4 回滚历史版本
- 相关git命令
1.git branch:查看当前分支，如果在后面加-a则表示查看所有分支。
2.git log:查看提交历史，在commit id这一项中可以看到提交的历史版本id。
3.git reflog:查看每一次命令的记录
4.git reset --soft:回退到某个版本，只回退了commit的信息。
5.git reset --mixed:为默认方式，不带任何参数的git reset，即时这种方式，它回退到某个版本，只保留源码，回退commit和index信息。
6.git reset --hard:彻底回退到某个版本，本地的源码也会变为上一个版本的内容，撤销的commit中所包含的更改被冲掉。

- 步骤
1.回滚到指定版本
首先进入项目根目录下，使用git log 命令，找到需要返回的commit id 号，使用git reset --hard 后跟你需要的commit id号，这样你就回到了指定的版本，注意git reset --hard与git reset  --soft的区别：
git reset –-soft：回退到某个版本，只回退了commit的信息，不会恢复到index file一级。通常使用在当你git commit -m "注释"提交了你修改的内容，但内容有点问题想撤销，又还要提交，就使用soft，相当于软着路；
git reset -–hard：彻底回退到某个版本，本地的源码也会变为上一个版本的内容，撤销的commit中所包含的更改被冲掉，相当于硬着路，回滚最彻底。

   2.返回到最新版本
当你发现需要回滚到最新版本时，可以采用以下指今步骤
git log：查看历史提交
git reflog：查看每一次命令记录
通过git reflog命令查看到之后，我们再利用 git reset 来返回到相应的版本即可，HEAD前面的一串字符为我们简写的ID，所以最后输入
git reset --hard ca936c3即回滚到了最新的版本号了

>如果出现Unstaged changes after reset:提示，可以使用git stash和git stash drop命令后再执行reset命令。

### 6.5 git stash用法
我们有时会遇到这样的情况，正在dev分支开发新功能，做到一半时有人过来反馈一个bug，让马上解决，但是新功能做到了一半你又不想提交，这时就可以使用git stash命令先把当前进度（工作区和暂存区）保存起来，然后切换到另一个分支去修改bug，修改完提交后，再切回dev分支，使用git stash pop来恢复之前的进度继续开发新功能。

- 相关命令
1.git stash : 存储工作区和缓存区
2.git stash save "msg" : 存储工作区和缓存区并起名字
3.git stash list : 查看之前存储的所有版本列表
4.git stash pop [stash_id] : 恢复具体某一次的版本，如果不指定stash_id，则默认恢复最新的存储进度(恢复之后，有时打开工程文件，会发现里面所有文件都不翼而飞了？！这是因为出现合并冲突的问题而导致工程文件打不开。这时候右击工程文件，单击“显示包内容”，打开“project.pbxproj”文件，然后command + f 搜索 “stashed”。把冲突部分删掉就可以重新打开啦)
5. git stash apply [stash_id] : 将堆栈中的内容应用到当前目录，不同于git stash pop，该命令不会将内容从堆栈中删除，也就说该命令能够将堆栈的内容多次应用到工作目录中，适应于多个分支的情况。如果不指定stash_id，则默认最新的存储进度。
6.git stash drop [stash_id] : 删除一个存储的进度。如果不指定stash_id，则默认删除最新的存储进度。
7.git stash clear : 清除所有的存储进度
8.git stash show : 查看堆栈中最新保存的stash和当前目录的差异。如果不指定stash_id，则默认删除最新的存储进度。git stash show -p 查看详细的不同
9.git stash branch : 从最新的stash创建分支。应用场景：当储藏了部分工作，暂时不去理会，继续在当前分支进行开发，后续想将stash中的内容恢复到当前工作目录时，如果是针对同一个文件的修改（即便不是同行数据），那么可能会发生冲突，恢复失败，这里通过创建新的分支来解决。可以用于解决stash中的内容和当前目录的内容发生冲突的情景。发生冲突时，需手动解决冲突。


### 分支操作
- 命令
1.git branch -a : 查看所有分支(remote开头的是远程分支，否则是本地分支)
 git branch -m old_name new_name : 修改分支名字
2.git checkout branchname : 切换本地分支
3.git checkout -b 本地分支名 origin/远程分支名 : 切换远程分支。需要先将远程分支与本地分支关联。
4.git checkout .  : 放弃所有工作区的修改(工作区有被修改的文件，执行了命令后，放弃了所有的工作区的修改)
5.git checkout -f : 放弃工作区和暂存区(add命令将工作区保存到暂存区)的所有修改
6.git checkout filename  : 放弃对指定文件的修改
7.git branch -d  branch_name : 删除本地分支
8.git push remote_name -d remote_branch_name : 删除远程分支
9.git push remote_name local_branch_name:remote_branch_name : 将本地的分支版本上传到远程并合并。如果本地分支名与远程分支名相同，则可以省略remote_branch_name。
10.git push -f hifun prod : 如果本地版本与远程版本有差异，但又要强制推送可以使用 --force/-f 参数。

<br>
## NOTE
1. 可以使用命令建立本地分支与远程分支的映射 `git branch -u hifun/test test`
2. git checkout -- readme.txt 意思就是，把readme.txt文件在工作区的修改全部撤销，这里有两种情况：
   - 一种是readme.txt自修改后还没有被放到暂存区，现在，撤销修改就会到和版本库一模一样的状态；
   - 一种是readme.txt已经添加到暂存区后，又做了修改，现在撤销修改就回到添加到暂存区后的状态。

总之，就是让这个文件会到最近一次git commit或git add时的状态。
