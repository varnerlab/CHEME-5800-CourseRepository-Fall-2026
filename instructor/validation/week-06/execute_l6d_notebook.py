"""Execute L6d with reference answers in a temporary copy; leave student cells unchanged.

Requires Python nbformat, nbclient, nbconvert, and the Julia 1.12 Jupyter kernel.
Both light and dark plot themes are executed. Review exports go to --output-dir
or a newly created temporary directory; HTML is not a maintained course artifact.
"""
from pathlib import Path
import argparse, tempfile
import os, copy, shutil
import nbformat
from nbclient import NotebookClient
from nbconvert import HTMLExporter
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output-dir', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3] / 'weeks/week-06/L6d'
out = args.output_dir or Path(tempfile.mkdtemp(prefix='l6d-oxygen-review-'))
out.mkdir(parents=True, exist_ok=True)
os.environ['GKSwstype']='100'
os.environ['JUPYTER_RUNTIME_DIR']=str(out/'runtime')
os.environ['IPYTHONDIR']=str(out/'ipython')
source=nbformat.read(root/'CHEME-5800-L6d-Lab-IterativeLinearSolvers-Fall-2026.ipynb',as_version=4)
answers={
 'my_residual = nothing;':'my_residual = model.b - model.A * theta_initial;',
 'my_next = nothing;':'my_next = theta_initial + my_residual ./ diag(model.A);',
 'reduced_boundary = nothing;':'reduced_boundary = β / 2;'
}
for old,new in answers.items():
 assert sum(c.source.count(old) for c in source.cells)==1
 for c in source.cells: c.source=c.source.replace(old,new)
client=NotebookClient(source,timeout=180,kernel_name='julia-1.12',resources={'metadata':{'path':str(root)}})
client.execute()
nbformat.write(source,out/'lab-completed.ipynb')
print('Completed all lab code cells with the three reference answers.',flush=True)
shutil.copytree(root/'figs',out/'figs',dirs_exist_ok=True)
for name,nb in [('lab',source),('derivation',nbformat.read(root/'CHEME-5800-L6d-Derivation-OxygenDiffusionReaction-Fall-2026.ipynb',as_version=4))]:
 html,_=HTMLExporter().from_notebook_node(nb)
 (out/(name+'.html')).write_text(html)
print('Rendered lab and derivation to',out,flush=True)
# Execute the same completed lab under the dark plot theme.
dark=copy.deepcopy(source)
for c in dark.cells:
 if c.cell_type=='code':
  c.outputs=[]; c.execution_count=None
  c.source=c.source.replace('theme(:default)   # light background','theme(:dark)   # dark background')
NotebookClient(dark,timeout=180,kernel_name='julia-1.12',resources={'metadata':{'path':str(root)}}).execute()
nbformat.write(dark,out/'lab-completed-dark.ipynb')
html,_=HTMLExporter().from_notebook_node(dark)
(out/'lab-dark.html').write_text(html)
print('Completed and rendered the dark-theme lab.',flush=True)
