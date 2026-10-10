"""Execute L8d with the reference my_cross_validation(...) in a temporary copy.

The tracked lab keeps the student stub in src/Compute.jl and ships without outputs.
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
source_root = Path(__file__).resolve().parents[3] / 'weeks/week-08/L8d'
notebook_name = 'CHEME-5800-L8d-Lab-CrossValidationAndResidualModelChecking-Fall-2026.ipynb'
# Execute a sibling copy so the reference my_cross_validation(...) can replace the
# student stub without touching the tracked lab; the relative path to the root
# Include.jl is unchanged because the copy sits at the same depth.
root = source_root.parent / '.L8d-review-copy'
import atexit; atexit.register(shutil.rmtree, root, True) # registered first, so a failed copy is also removed
shutil.rmtree(root, ignore_errors=True)
shutil.copytree(source_root, root, ignore=shutil.ignore_patterns('.ipynb_checkpoints'))
shutil.copyfile(root/'src'/'Compute-solution.jl', root/'src'/'Compute.jl')
out = args.output_dir or Path(tempfile.mkdtemp(prefix='l8d-cross-validation-review-'))
out.mkdir(parents=True, exist_ok=True)
os.environ['GKSwstype']='100'
os.environ['JUPYTER_RUNTIME_DIR']=str(out/'runtime')
os.environ['IPYTHONDIR']=str(out/'ipython')
source=nbformat.read(root/notebook_name,as_version=4)
client=NotebookClient(source,timeout=600,kernel_name='julia-1.12',resources={'metadata':{'path':str(root)}})
client.execute()
nbformat.write(source,out/'lab-completed.ipynb')
html,_=HTMLExporter().from_notebook_node(source)
(out/'lab.html').write_text(html)
print('Completed and rendered the lab with the reference my_cross_validation(...) in',out,flush=True)
# Execute the same completed lab under the dark plot theme.
dark=copy.deepcopy(source)
for c in dark.cells:
 if c.cell_type=='code':
  c.outputs=[]; c.execution_count=None
  c.source=c.source.replace('theme(:default)   # light background','theme(:dark)   # dark background')
NotebookClient(dark,timeout=600,kernel_name='julia-1.12',resources={'metadata':{'path':str(root)}}).execute()
nbformat.write(dark,out/'lab-completed-dark.ipynb')
html,_=HTMLExporter().from_notebook_node(dark)
(out/'lab-dark.html').write_text(html)
print('Completed and rendered the dark-theme lab.',flush=True)
