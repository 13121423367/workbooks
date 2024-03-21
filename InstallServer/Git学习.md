[TOC]
# git 基础知识



## Git 状态切换 ★★★

```sequence
工作区 ->  暂存区: git add xxx
暂存区 ->  版本区: git commit -m "提交信息"
版本区 ->  服务器: git push origin master
服务器 --> 工作区: git pull
版本区 --> 暂存区: git reset HEAD
暂存区 --> 工作区: git checkout -- a.txt
版本区 --> 暂存区: git checkout HEAD a.txt
版本区 --> 工作区: git checkout HEAD a.txt

Note right of 服务器: Gitlab、Github等
Note right of 版本区: 已经被Git版本控制
Note right of 暂存区: 暂时保存，即将交给Git进行版本管理
Note right of 工作区: 项目文件夹，进行“增删改”的区域
```



## Gitlab新建仓库使用引导 ★★



### 创建一个新仓库

```
git clone http://doc.ops.pppcloud.cn/sunjianxing/test.git
cd test
git switch -c main
touch README.md
git add README.md
git commit -m "add README"
git push -u origin main
```

### 推送现有文件夹

```
cd existing_folder
git init --initial-branch=main
git remote add origin http://doc.ops.pppcloud.cn/sunjianxing/test.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 推送现有的 Git 仓库

```
cd existing_repo
git remote rename origin old-origin
git remote add origin http://doc.ops.pppcloud.cn/sunjianxing/test.git
git push -u origin --all
git push -u origin --tags
```



## git config ★★★



> git config 指定一个配置项，如果不指定配置内容就是查看配置内容，如果没有配置过不会显示信息，类似查看一个空变量。如果指定了配置内容就是定义或者修改配置内容，仅保存最后一次定义的内容。
>
> git config 可以保存在两个地方，一个是全局配置文件，在用户家目录下面的 `~/.gitconfig` 文件中。一个是当前代码库的配置文件中，在`.git/config` 文件中。



### 配置用户信息

**定义用户信息**

```bash
$ git config --global user.name "sunjianxing"
$ git config --global user.email  "sunjianxing@xinnet.com"
$ git config user.name "www1707"
$ git config user.email  "www1707@163.com"
```

**查看用户信息**

```bash
$ git config user.name
www1707
$ git config user.email
www1707@163.com
$ git config --global user.name
sunjianxing
$ git config --global user.email
sunjianxing@xinnet.com
```

**查看配置文件**

```bash
$ cat ~/.gitconfig
[user]
        email = sunjianxing@xinnet.com
        name = sunjianxing
$ cat .git/config
[core]
        repositoryformatversion = 0
        filemode = false
        bare = false
        logallrefupdates = true
        symlinks = false
        ignorecase = true
[remote "origin"]
        url = http://doc.ops.pppcloud.cn/ops/dairy.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
        remote = origin
        merge = refs/heads/main
[user]
        name = www1707
        email = www1707@163.com
```



### 配置不自动转换回车换行符

```bash
www1707@DESKTOP-MRCFFUS MINGW64 /d/USERDATA/Git/dairy (main)
$ git config --global core.autocrlf

www1707@DESKTOP-MRCFFUS MINGW64 /d/USERDATA/Git/dairy (main)
$ git config --global core.autocrlf false

www1707@DESKTOP-MRCFFUS MINGW64 /d/USERDATA/Git/dairy (main)
$ git config --global core.autocrlf
false

www1707@DESKTOP-MRCFFUS MINGW64 /d/USERDATA/Git/dairy (main)
$ cat ~/.gitconfig
[user]
        email = sunjianxing@xinnet.com
        name = sunjianxing
[core]
        autocrlf = false
```



## git status ★★



> 查看Git当前状态，处于什么区。



**创建一个空目录，查看状态**

```bash
$ mkdir test
$ cd test
$ git status
fatal: not a git repository (or any of the parent directories): .git
```

**初始化一个空代码库，查看状态**

```bash
$ git init
Initialized empty Git repository in D:/USERDATA/Git/test/.git/
$ git status
On branch master

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

**将本地代码库和远端仓库建立连接，查看状态**

```bash
$ git remote add origin http://doc.ops.pppcloud.cn/sunjianxing/test.git
$ git status
On branch master

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

**git add 空，查看状态**

```bash
$ git add .
$ git status
On branch master

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

**创建一个文件，查看状态**

```bash
$ touch test.file
$ git status
On branch master

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        test.file （红色）

nothing added to commit but untracked files present (use "git add" to track)
```

**git add 之后，查看状态**

```bash
$ git add .
$ git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   test.file （绿色）
```

**git commit 之后，查看状态**

```bash
$ git commit -m "提交"
[master (root-commit) b353cb9] 提交
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 test.file

$ git status
On branch master
nothing to commit, working tree clean
```

**git push 之后，查看状态**

```bash
$ git push -u origin master
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Writing objects: 100% (3/3), 213 bytes | 213.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To http://doc.ops.pppcloud.cn/sunjianxing/test.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.

$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
```

**再创建一个文件，查看状态**

```bash
$ touch test.file2
$ git status
On branch master
Your branch is up to date with 'origin/master'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        test.file2 （红色）

nothing added to commit but untracked files present (use "git add" to track)
```

**git add 之后，查看状态**

```bash
$ git add .
$ git status
On branch master
Your branch is up to date with 'origin/master'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   test.file2 （绿色）
```

**git commit 之后，查看状态**

```bash
$ git commit -m "提交2"
[master 7963597] 提交2
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 test.file2

$ git status
On branch master
Your branch is ahead of 'origin/master' by 1 commit.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

**git push 之后，查看状态** 

```bash
$ git push -u origin master
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Delta compression using up to 4 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (2/2), 244 bytes | 244.00 KiB/s, done.
Total 2 (delta 0), reused 0 (delta 0), pack-reused 0
To http://doc.ops.pppcloud.cn/sunjianxing/test.git
   b353cb9..7963597  master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.

$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
```



## git diff ★



> 对比各区之间的差异

```sequence
工作区 -> 暂存区: git add .
暂存区 -> 版本区: git commit -m ''
暂存区 --> 工作区: git diff
版本区 --> 暂存区: git diff --cached
版本区 --> 工作区: git diff master

```

## git log ★★★



> 查看提交记录，按照从近到远的顺序显示



```bash
$ mkdir gitlog
$ cd gitlog
$ git init
Initialized empty Git repository in D:/Desktop/Git/gitlog/.git/

$ echo 1111 >> file
$ git add . ; git commit -m "第 1 次提交"
[master (root-commit) 48933cd] 第 1 次提交
 1 file changed, 1 insertion(+)
 create mode 100644 file

$ echo 2222 >> file
$ git add . ; git commit -m "第 2 次提交"
[master 3af1f9b] 第 2 次提交
 1 file changed, 1 insertion(+)

$ echo 3333 >> file
$ git add . ; git commit -m "第 3 次提交"
[master 3eacd11] 第 3 次提交
 1 file changed, 1 insertion(+)

$ echo 4444 >> file
$ git add . ; git commit -m "第 4 次提交"
[master 0a5331f] 第 4 次提交
 1 file changed, 1 insertion(+)

$ echo 5555 >> file
$ git add . ; git commit -m "第 5 次提交"
[master 007dd2f] 第 5 次提交
 1 file changed, 1 insertion(+)

$ git log
commit 007dd2ffb119265a978f4adaf21613b5e0a381c7 (HEAD -> master)
Author: sunjianxing <sunjianxing@xinnet.com>
Date:   Fri Jul 2 22:33:39 2021 +0800

    第 5 次提交

commit 0a5331f9fbdc97b2d15929dc3c7671541dce1a79
Author: sunjianxing <sunjianxing@xinnet.com>
Date:   Fri Jul 2 22:33:29 2021 +0800

    第 4 次提交

commit 3eacd119983545a25dfe1bd85c7877bf0cd0033e
Author: sunjianxing <sunjianxing@xinnet.com>
Date:   Fri Jul 2 22:33:14 2021 +0800

    第 3 次提交

commit 3af1f9b21b7290198ad9b1931ad994a0a0a3dcff
Author: sunjianxing <sunjianxing@xinnet.com>
Date:   Fri Jul 2 22:33:04 2021 +0800

    第 2 次提交

commit 48933cdb17d1db4f71b197ee6732838cbc8e615e
Author: sunjianxing <sunjianxing@xinnet.com>
Date:   Fri Jul 2 22:32:48 2021 +0800

    第 1 次提交

```



## git reflog ★★★



> 查看精简的提交记录，同样是按照从近到远的顺序显示



```bash
$ git reflog
007dd2f (HEAD -> master) HEAD@{0}: commit: 第 5 次提交
0a5331f HEAD@{1}: commit: 第 4 次提交
3eacd11 HEAD@{2}: commit: 第 3 次提交
3af1f9b HEAD@{3}: commit: 第 2 次提交
48933cd HEAD@{4}: commit (initial): 第 1 次提交

```

## git ls-files

> 查看所有文件状态

```bash
git ls-files -s
                                                #状态
100644 0c316afd412a0610679c53b175a64ff9f29baafe 0       test.txt
100644 ef3e13c70594d8197cad66a3537b4cf1f5c6cc8c 1       test.txt.orig
100644 410d1757b90539ade872ec4a45343ea9c3edbe0e 2      test1.txt


#状态解析
- 0 ：没有冲突
- 1/2 ：有冲突
```



## git mergetool ★★

> 可视化界面，解决文件冲突问题

```bash
git mergetool
#手动合并内容后再添加、提交即可
```



## git reset



> 版本回退，回退到上一版本、上上版本、指定版本（48933cd）



```bash
git reset --hard HEAD^

git reset --hard HEAD^^

git reset --hard 48933cd
```



> 用版本库中的文件去替换暂存区的全部文件



```bash
git reset HEAD
```



## git checkout



> 用暂存区的文件覆盖工作区的文件，不可恢复



```bash
git checkout -- a.txt
```



> 工作区 a.txt 1111
>
> 暂存区 a.txt 1111 2222



```bash
www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff
diff --git a/a.txt b/a.txt
index 4f142ee..5f2f16b 100644
--- a/a.txt
+++ b/a.txt
@@ -1,2 +1 @@
 1111
-2222

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git checkout -- a.txt

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ cat a.txt
1111
2222
```



> 用版本区的文件覆盖暂存区和工作区的文件，不可恢复



```bash
git checkout HEAD a.txt
```


> 工作区 a.txt 1111
>
> 暂存区 a.txt 1111 2222
>
> 版本区 a.txt 1111 2222 3333



```bash
www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff
diff --git a/a.txt b/a.txt
index 4f142ee..5f2f16b 100644
--- a/a.txt
+++ b/a.txt
@@ -1,2 +1 @@
 1111
-2222

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff --cached
diff --git a/a.txt b/a.txt
index e0037f0..4f142ee 100644
--- a/a.txt
+++ b/a.txt
@@ -1,3 +1,2 @@
 1111
 2222
-3333

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff master
diff --git a/a.txt b/a.txt
index e0037f0..5f2f16b 100644
--- a/a.txt
+++ b/a.txt
@@ -1,3 +1 @@
 1111
-2222
-3333

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git checkout HEAD a.txt
Updated 1 path from b50c6f8

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff --cached

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git diff master

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ cat a.txt
1111
2222
3333
```



## git rm



> 同时从工作区和暂存区删除文件或者目录



```bash
git rm a.txt
git rm -r dira
```



> 只从暂存区删除文件



```bash
git rm --cached a.txt
```



> 只从工作区删除文件



```bash
rm a.txt
```



## git help



```bash
www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git help
usage: git [--version] [--help] [-C <path>] [-c <name>=<value>]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--bare]
           [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]
           [--super-prefix=<path>] [--config-env=<name>=<envvar>]
           <command> [<args>]

These are common Git commands used in various situations:

start a working area (see also: git help tutorial)
   clone             Clone a repository into a new directory
   init              Create an empty Git repository or reinitialize an existing one

work on the current change (see also: git help everyday)
   add               Add file contents to the index
   mv                Move or rename a file, a directory, or a symlink
   restore           Restore working tree files
   rm                Remove files from the working tree and from the index
   sparse-checkout   Initialize and modify the sparse-checkout

examine the history and state (see also: git help revisions)
   bisect            Use binary search to find the commit that introduced a bug
   diff              Show changes between commits, commit and working tree, etc
   grep              Print lines matching a pattern
   log               Show commit logs
   show              Show various types of objects
   status            Show the working tree status

grow, mark and tweak your common history
   branch            List, create, or delete branches
   commit            Record changes to the repository
   merge             Join two or more development histories together
   rebase            Reapply commits on top of another base tip
   reset             Reset current HEAD to the specified state
   switch            Switch branches
   tag               Create, list, delete or verify a tag object signed with GPG

collaborate (see also: git help workflows)
   fetch             Download objects and refs from another repository
   pull              Fetch from and integrate with another repository or a local branch
   push              Update remote refs along with associated objects

'git help -a' and 'git help -g' list available subcommands and some
concept guides. See 'git help <command>' or 'git help <concept>'
to read about a specific subcommand or concept.
See 'git help git' for an overview of the system.

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git help -a
See 'git help <command>' to read about a specific subcommand

Main Porcelain Commands
   add                  Add file contents to the index
   am                   Apply a series of patches from a mailbox
   archive              Create an archive of files from a named tree
   bisect               Use binary search to find the commit that introduced a bug
   branch               List, create, or delete branches
   bundle               Move objects and refs by archive
   checkout             Switch branches or restore working tree files
   cherry-pick          Apply the changes introduced by some existing commits
   citool               Graphical alternative to git-commit
   clean                Remove untracked files from the working tree
   clone                Clone a repository into a new directory
   commit               Record changes to the repository
   describe             Give an object a human readable name based on an available ref
   diff                 Show changes between commits, commit and working tree, etc
   fetch                Download objects and refs from another repository
   format-patch         Prepare patches for e-mail submission
   gc                   Cleanup unnecessary files and optimize the local repository
   gitk                 The Git repository browser
   grep                 Print lines matching a pattern
   gui                  A portable graphical interface to Git
   init                 Create an empty Git repository or reinitialize an existing one
   log                  Show commit logs
   maintenance          Run tasks to optimize Git repository data
   merge                Join two or more development histories together
   mv                   Move or rename a file, a directory, or a symlink
   notes                Add or inspect object notes
   pull                 Fetch from and integrate with another repository or a local branch
   push                 Update remote refs along with associated objects
   range-diff           Compare two commit ranges (e.g. two versions of a branch)
   rebase               Reapply commits on top of another base tip
   reset                Reset current HEAD to the specified state
   restore              Restore working tree files
   revert               Revert some existing commits
   rm                   Remove files from the working tree and from the index
   shortlog             Summarize 'git log' output
   show                 Show various types of objects
   sparse-checkout      Initialize and modify the sparse-checkout
   stash                Stash the changes in a dirty working directory away
   status               Show the working tree status
   submodule            Initialize, update or inspect submodules
   switch               Switch branches
   tag                  Create, list, delete or verify a tag object signed with GPG
   worktree             Manage multiple working trees

Ancillary Commands / Manipulators
   config               Get and set repository or global options
   fast-export          Git data exporter
   fast-import          Backend for fast Git data importers
   filter-branch        Rewrite branches
   mergetool            Run merge conflict resolution tools to resolve merge conflicts
   pack-refs            Pack heads and tags for efficient repository access
   prune                Prune all unreachable objects from the object database
   reflog               Manage reflog information
   remote               Manage set of tracked repositories
   repack               Pack unpacked objects in a repository
   replace              Create, list, delete refs to replace objects

Ancillary Commands / Interrogators
   annotate             Annotate file lines with commit information
   blame                Show what revision and author last modified each line of a file
   bugreport            Collect information for user to file a bug report
   count-objects        Count unpacked number of objects and their disk consumption
   difftool             Show changes using common diff tools
   fsck                 Verifies the connectivity and validity of the objects in the database
   gitweb               Git web interface (web frontend to Git repositories)
   help                 Display help information about Git
   instaweb             Instantly browse your working repository in gitweb
   merge-tree           Show three-way merge without touching index
   rerere               Reuse recorded resolution of conflicted merges
   show-branch          Show branches and their commits
   verify-commit        Check the GPG signature of commits
   verify-tag           Check the GPG signature of tags
   whatchanged          Show logs with difference each commit introduces

Interacting with Others
   archimport           Import a GNU Arch repository into Git
   cvsexportcommit      Export a single commit to a CVS checkout
   cvsimport            Salvage your data out of another SCM people love to hate
   cvsserver            A CVS server emulator for Git
   imap-send            Send a collection of patches from stdin to an IMAP folder
   p4                   Import from and submit to Perforce repositories
   quiltimport          Applies a quilt patchset onto the current branch
   request-pull         Generates a summary of pending changes
   send-email           Send a collection of patches as emails
   svn                  Bidirectional operation between a Subversion repository and Git

Low-level Commands / Manipulators
   apply                Apply a patch to files and/or to the index
   checkout-index       Copy files from the index to the working tree
   commit-graph         Write and verify Git commit-graph files
   commit-tree          Create a new commit object
   hash-object          Compute object ID and optionally creates a blob from a file
   index-pack           Build pack index file for an existing packed archive
   merge-file           Run a three-way file merge
   merge-index          Run a merge for files needing merging
   mktag                Creates a tag object with extra validation
   mktree               Build a tree-object from ls-tree formatted text
   multi-pack-index     Write and verify multi-pack-indexes
   pack-objects         Create a packed archive of objects
   prune-packed         Remove extra objects that are already in pack files
   read-tree            Reads tree information into the index
   symbolic-ref         Read, modify and delete symbolic refs
   unpack-objects       Unpack objects from a packed archive
   update-index         Register file contents in the working tree to the index
   update-ref           Update the object name stored in a ref safely
   write-tree           Create a tree object from the current index

Low-level Commands / Interrogators
   cat-file             Provide content or type and size information for repository objects
   cherry               Find commits yet to be applied to upstream
   diff-files           Compares files in the working tree and the index
   diff-index           Compare a tree to the working tree or index
   diff-tree            Compares the content and mode of blobs found via two tree objects
   for-each-ref         Output information on each ref
   for-each-repo        Run a Git command on a list of repositories
   get-tar-commit-id    Extract commit ID from an archive created using git-archive
   ls-files             Show information about files in the index and the working tree
   ls-remote            List references in a remote repository
   ls-tree              List the contents of a tree object
   merge-base           Find as good common ancestors as possible for a merge
   name-rev             Find symbolic names for given revs
   pack-redundant       Find redundant pack files
   rev-list             Lists commit objects in reverse chronological order
   rev-parse            Pick out and massage parameters
   show-index           Show packed archive index
   show-ref             List references in a local repository
   unpack-file          Creates a temporary file with a blob's contents
   var                  Show a Git logical variable
   verify-pack          Validate packed Git archive files

Low-level Commands / Syncing Repositories
   daemon               A really simple server for Git repositories
   fetch-pack           Receive missing objects from another repository
   http-backend         Server side implementation of Git over HTTP
   send-pack            Push objects over Git protocol to another repository
   update-server-info   Update auxiliary info file to help dumb servers

Low-level Commands / Internal Helpers
   check-attr           Display gitattributes information
   check-ignore         Debug gitignore / exclude files
   check-mailmap        Show canonical names and email addresses of contacts
   check-ref-format     Ensures that a reference name is well formed
   column               Display data in columns
   credential           Retrieve and store user credentials
   credential-cache     Helper to temporarily store passwords in memory
   credential-store     Helper to store credentials on disk
   fmt-merge-msg        Produce a merge commit message
   interpret-trailers   Add or parse structured information in commit messages
   mailinfo             Extracts patch and authorship from a single e-mail message
   mailsplit            Simple UNIX mbox splitter program
   merge-one-file       The standard helper program to use with git-merge-index
   patch-id             Compute unique ID for a patch
   sh-i18n              Git's i18n setup code for shell scripts
   sh-setup             Common Git shell script setup code
   stripspace           Remove unnecessary whitespace

External commands
   askyesno
   credential-helper-selector
   flow
   lfs

www17@DESKTOP-DMG2021 MINGW64 /d/Desktop/Git/gitlog (master)
$ git help -g

The Git concept guides are:
   attributes          Defining attributes per path
   cli                 Git command-line interface and conventions
   core-tutorial       A Git core tutorial for developers
   credentials         Providing usernames and passwords to Git
   cvs-migration       Git for CVS users
   diffcore            Tweaking diff output
   everyday            A useful minimum set of commands for Everyday Git
   faq                 Frequently asked questions about using Git
   glossary            A Git Glossary
   hooks               Hooks used by Git
   ignore              Specifies intentionally untracked files to ignore
   mailmap             Map author/committer names and/or E-Mail addresses
   modules             Defining submodule properties
   namespaces          Git namespaces
   remote-helpers      Helper programs to interact with remote repositories
   repository-layout   Git Repository Layout
   revisions           Specifying revisions and ranges for Git
   submodules          Mounting one repository inside another
   tutorial            A tutorial introduction to Git
   tutorial-2          A tutorial introduction to Git: part two
   workflows           An overview of recommended workflows with Git

'git help -a' and 'git help -g' list available subcommands and some
concept guides. See 'git help <command>' or 'git help <concept>'
to read about a specific subcommand or concept.
See 'git help git' for an overview of the system.
```



## Branches & Tags



> dev	研发分支
>
> test	测试分支
>
> master	主分支，正式分支
>
> tags	里程碑分支 v1.0.0



分享哔哩哔哩课件

创建并切换到分支

每人一个分支，合并验证

代码编辑器集成git的使用

git revert

