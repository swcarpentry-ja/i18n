from argparse import ArgumentParser
import glob
import os
from pathlib import Path
import shutil
import tempfile

from git import Repo
from github import Github
from ruamel.yaml import YAML


def clone_repo_as_submodule(org, project, tmpdir='/tmp'):
    '''
    org: swcarpentry
    project: git-novice
    '''

    tmpdir = Path(tmpdir)
    if os.environ['gh_access_token']:
        g = Github(os.environ['gh_access_token'])
    else:
        # ask for user name and password
        # g = Github(username, password)
        raise NotImplementedError
    github_user = g.get_user()

    # from carpentries URL git repo to new Repo in swc-i18n
    repo = g.get_repo(f'{org}/{project}')
    # Fork repository
    carp_18n_org = [n for n in github_user.get_orgs() if "i18n" in n.login][0]
    # it doesn't create it if it exists.
    carp_i18n_fork = carp_18n_org.create_fork(repo)
    carp_i18n_fork.edit(homepage=f"https://carpentries-i18n.github.io/{project}/")

    i18n_local = Repo(".") # FIXME How should I pass the directory?


    sm_exists = any(filter(lambda x: f"{project}" in x.name, i18n_local.submodules))

    if sm_exists:
        return i18n_local, Repo(f"{project}"), carp_i18n_fork, github_user

    # Creates a new branch for keep this lesson changes
    project_branch = i18n_local.create_head(project)
    i18n_local.head.reference = project_branch
    project_sm = i18n_local.create_submodule(project, project, url=carp_i18n_fork.clone_url)
    project_sm.update()
    # Clone repository
    i18n_local.index.commit(f"Adds {project} submodule.")
    return i18n_local, Repo(f"{project}"), repo, carp_i18n_fork, project_sm, github_user


def clean_wrong_format(directory):

    files = glob.glob(f"{directory}/**/*md")
    changes = 0
    for f in files:
        with open(f, 'r') as mdfile:
            all_lines = mdfile.readlines()
            bad_lines = []
            for i, line in enumerate(all_lines):
                if "{:" in line:
                    # This is to cover whether the line starts with {: or with > {:
                    if set(all_lines[i-1].split()) == set('>'):
                           bad_lines.append(i-1)
        if bad_lines:
            changes += 1
            bad_lines.reverse()
            with open(f, 'w') as mdfile:
                for bad_line in bad_lines:
                    all_lines.pop(bad_line)
                mdfile.writelines(all_lines)

    return changes


def themetise_lesson(clone):

    branch_ghpages = clone.create_head("gh_pages_theme")
    clone.head.reference = branch_ghpages

    # Clean repository
    # what's provided by theme
    dir_remove = ['_layouts', '_includes', '_episodes_rmd', 'assets', 'bin', 'code', 'css'] #, 'files']
    for entry in os.listdir(clone.working_dir):
        if entry in dir_remove and os.path.isdir(os.path.join(clone.working_dir, entry)):
            shutil.rmtree(os.path.join(clone.working_dir, entry))

    # add theme to `_config.yml`
    yaml = YAML()
    with open(clone.working_dir + '/_config.yml') as mm:
        config = yaml.load(mm)

    config.insert(1, 'remote_theme', "carpentries-i18n/carp-theme", comment="Theme URL")

    elem_remove = ['amy_site', 'carpentries_github', 'carpentries_pages', 'carpentries_site',
                   'dc_site', 'example_repo', 'example_site', 'lc_site', 'swc_github',
                   'swc_pages', 'swc_site', 'template_repo', 'training_site',
                   'workshop_repo', 'workshop_site', 'pre_survey', 'post_survey',
                   'training_post_survey']
    for elem in elem_remove:
        if elem in config:
            config.pop(elem)

    with open(clone.working_dir + '/_config.yml', 'w') as mm:
        yaml.dump(config, mm)


    clone.git.add(update=True)
    clone.index.commit('Removed all files that are provisioned by theme.')

    # Add locale bits to config
    with open(clone.working_dir + '/_config.yml') as mm:
        config = yaml.load(mm)

    config['collections']['locale'] = {'output': True,
                                       'permalink': '/:path/index.html'}
    config['defaults'].append({'scope': {'path': "", 'type': "locale"},
                               'values': {'root': "..", 'layout': "episode"}})
    with open(clone.working_dir + '/_config.yml', 'w') as mm:
        yaml.dump(config, mm)

    with open(clone.working_dir + "/aio.md", "r") as f:
        contents = f.readlines()

    to_add = ['layout: page\n', 'permalink: /aio/\n']
    for i, line in enumerate(to_add):
        if line not in contents:
            contents.insert(i+1, line)
    contents = "".join(contents)

    with open(clone.working_dir + "/aio.md", "w") as f:
        f.write(contents)

    clone.git.add(update=True)
    clone.index.commit('add bits to _config.yml to allow translations.')


def main(project):

    org, project = project.split('/')
    parent, clone, upstream, fork, submod, github_user = clone_repo_as_submodule(org, project)
    # add new remote with token so we can push
    new_url = fork.html_url.replace('://',
                                    f"://{github_user.login}:{os.environ['gh_access_token']}@")
    clone.create_remote("topush", url=new_url)

    changes = clean_wrong_format(clone.working_dir)
    if changes:
        branch_format = clone.create_head("update_format")
        clone.head.reference = branch_format
        clone.git.add(update=True)
        clone.index.commit(f"[translations] Fixed format that affects translations on {changes} file(s).")
        clone.git.push("topush", "update_format")
        # Create PR
        # NOTE - this only seem to work on repositories where I have permission.
        upstream.create_pull("[translations] Clean lessons to create po files",
                             "The `po` files are the tokenised version of the lessons. The [tool we are using](https://github.com/carpentries-i18n/po4gitbook) complains if the following *typos* or empty lines at the end of sections are not fixed.",
                             'gh-pages',
                             'carpentries-i18n:update_format',
                             True)

    #TODO  Test if builds cleanly.
    themetise_lesson(clone)

    # push repository
    clone.git.push("topush", "gh_pages_theme:gh-pages")
    print(f"Check {fork.html_url}/settings to see whether page is building OK")

    submod.binsha = submod.module().head.commit.binsha
    parent.index.add([submod])
    parent.index.commit(f"Updates {project} to include theme.")
    parent.git.push("origin", f"{project}")

    # TODO:
    # - Create PR with the formatting changes

if __name__ == "__main__":
    parser = ArgumentParser(description="Cleanup of repository according translation template")
    parser.add_argument('project', help='org/repo that you want to fork and theme from the carpentries')
    arguments = parser.parse_args()

    main(arguments.project)

    project = arguments.project.split('/')[1]
    print("If successful, run the following:")
    print(f"1. Generate the po with po4gitbook/update.sh")
    print(f"2. Break the file into chunks with python helpers/splitpot.py po/{project}.pot")
    print(f"3. Create a language directory on the transifex lesson directory: e.g., mkdir -p transifex/{project}/es")
    print(f"4. Build the transifex lesson: ")
    print(f"       - cd transifex/{project}")
    print(f"       - tx config mapping-bulk -p {project} --source-language en --type PO -f '.pot' \ ")
    print("                   --source-file-dir pot --expression \"<lang>/{filename}.po\" --execute ")
    print(f"5. Create the project {project} in transifex: https://www.transifex.com/carpentries-i18n/add/")
    print(f"6. Push the project to transifex: tx push -s --parallel")
