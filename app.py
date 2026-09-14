from pathlib import Path
import os
import sys
from runtime import entry,parser,run

CATEGORIES=['SYSTEM','NETWORK','FILES','GIT','SSH','ANDROID','BACKUP','DIAGNOSTICS']

def command(category,root):
    root=str(Path(root).resolve())
    commands={'SYSTEM':['uname','-a'],'NETWORK':['ip','address'],'FILES':['ls','-la','--',root],
       'GIT':['git','-C',root,'status','--short'],'SSH':['ssh','-Q','key'],'ANDROID':['termux-battery-status'],'DIAGNOSTICS':['termux-info']}
    if category not in commands:raise ValueError('Nieprawidłowa kategoria.')
    return commands[category]

def build():
    p=parser('Panel narzędzi Termux; korzysta z backendów systemowych.')
    p.add_argument('category',nargs='?',choices=CATEGORIES);p.add_argument('--menu',action='store_true')
    p.add_argument('--root',default='.');p.add_argument('--archive');p.add_argument('--apply',action='store_true')
    return p

def handle(a):
    if a.menu:
        for i,name in enumerate(CATEGORIES,1):print(f'{i}. {name}',file=sys.stderr)
        print('0. Wyjście',file=sys.stderr);selection=input('Wybierz: ').strip()
        if selection=='0':return {'exit':True}
        if not selection.isdigit() or not 1<=int(selection)<=len(CATEGORIES):raise ValueError('Nieprawidłowy wybór.')
        a.category=CATEGORIES[int(selection)-1]
    if not a.category:return {'menu':CATEGORIES,'support':'--support'}
    if a.category=='BACKUP':
        source=Path(a.root).resolve()
        if not source.is_dir() or source.is_symlink() or not a.archive:raise ValueError('Wskaż folder i archive.')
        target=Path(a.archive).resolve()
        if target.is_relative_to(source) or target.exists():raise ValueError('Nowe archiwum musi być poza źródłem.')
        cmd=['tar','--exclude=.ssh','--exclude=.env*','--exclude=.git','--exclude=*token*','--exclude=*password*','--exclude=*secret*','--exclude=*.pem','--exclude=*.key','-czf',str(target),'-C',str(source),'.']
        if not a.apply:return {'plan':cmd}
        run(cmd,600);return {'archive':str(target)}
    return {'category':a.category,'result':run(command(a.category,a.root),60)}

if __name__=='__main__':sys.exit(entry(build,handle))
