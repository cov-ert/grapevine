configfile: workflow.current_basedir + "/config.yaml"

import datetime

date = datetime.date.today()

##### Configuration #####

if config.get("output_path"):
    config["output_path"] = config["output_path"].rstrip("/")
else:
    config["output_path"] = "analysis"

LINEAGES = lineages.split()
OUTGROUPS = lineage_specific_outgroups.split()

##### Target rules #####

rule all:
    input:
        expand(tmp.{lineage}.{outgroup}.txt, zip, lineage=LINEAGES, outgroup=OUTGROUPS)

rule make_file:
    params:
        lineage = "{lineage}"
        outgroup = "{outgroup}"
    output:
        tmp.{lineage}.{outgroup}.txt
    shell:
        """
        touch {output}
        """

# rule all:
#     input:
#         rules.gisaid_filter_low_coverage_sequences.output,
#         rules.gisaid_process_json.output.metadata,
#         rules.uk_filter_low_coverage_sequences.output,
#         #rules.uk_fix_headers.output.metadata
#
# rule iq_tree:
#     input:
#         lineage_fasta = config["lineage_fasta"]
#     params:
#         lineage_specific_outgroup = config["lineage_specific_outgroup"],
#         lineage = config["lineage"]
#     output:
#         tree = config["output_path"] + "/4/{params.lineage}/cog_gisaid_%s_{params.lineage}.tree" %date
#     log:
#         config["output_path"] + "/logs/4_iq_tree_{params.lineage}.log"
#     shell:
#         """
#         iqtree -m GTR+G -bb 1000 -czb \
#         -o {params.lineage_specific_outgroup} \
#         -s {input.lineage_fasta} &> {log}
#         mv {input.lineage_fasta}.treefile {output.tree}
#         """
#
# rule annotate_tree:
#     input:
#         tree = rules.iq_tree.output.tree,
#         metadata = config["metadata"]
#     params:
#         lineage = config["lineage"]
#     output:
#         tree = config["output_path"] + "/4/{params.lineage}/cog_gisaid_%s_{params.lineage}.annotated.tree" %date
#     log:
#         config["output_path"] + "/logs/4_annotate_{params.lineage}.log"
#     shell:
#         """
#         clusterfunk annotate_tips \
#           --in-metadata {input.metadata} \
#           --trait-columns lineage \
#           country uk_lineage \
#           --index-column sequence_name \
#           --where-trait country_uk=UK \
#           --input {input.tree} \
#           --format newick \
#           --output {output.tree} &> {log}
#         """
#
# rule ancestral_reconstruction:
#     input:
#         tree = rules.annotate_tree.output.tree
#     params:
#         lineage = config["lineage"]
#     output:
#         tree = config["output_path"] + "/4/{params.lineage}/cog_gisaid_%s_{params.lineage}.annotated.acc.tree" %date
#     log:
#         config["output_path"] + "/logs/4_ancestral_reconstruction_{params.lineage}.log"
#     shell:
#         """
#         clusterfunk ancestral_reconstruction \
#         --traits country_uk \
#         --acctran \
#         --ancestral_state False \
#         --input {input.tree} \
#         --output {output.tree} &> {log}
#         """
#
# rule push_lineage_to_tips:
#     input:
#         tree = rules.ancestral_reconstruction.output.tree
#     params:
#         lineage = config["lineage"]
#     output:
#         tree = config["output_path"] + "/4/{params.lineage}/cog_gisaid_%s_{params.lineage}.annotated.acc.uk_lineages.tree" %date
#     log:
#         config["output_path"] + "/logs/4_push_lineage_to_tips_{params.lineage}.log"
#     shell:
#         """
#         clusterfunk push_annotations_to_tips \
#           --traits uk_lineage \
#           --stop-where-trait country_uk=False
#           --input {input.tree} \
#           --output {output.tree} &> {log}
#         """
#
# rule label_introductions:
#     input:
#         tree = rules.push_lineage_to_tips.output.tree
#     params:
#         lineage = config["lineage"]
#     output:
#         tree = config["output_path"] + "/4/{params.lineage}/cog_gisaid_%s_{params.lineage}.annotated.acc.uk_lineages.labelled.tree" %date
#     log:
#         config["output_path"] + "/logs/4_label_introductions_{params.lineage}.log"
#     shell:
#         """
#         clusterfunk label_transitions \
#           --trait country_uk \
#           --to True \
#           --transition-name acc_lineage \
#           --transition-prefix {params.lineage} \
#           --input {input.tree} \
#           --output {output.tree} &> {log}
#         """
#
# rule cut_out_trees:
#     input:
#         tree = rules.label_introductions.output.tree
#     params:
#         lineage = config["lineage"]
#     output:
#         outdir = config["output_path"] + "/4/{params.lineage}/trees"
#     log:
#         config["output_path"] + "/logs/4_cut_out_trees_{params.lineage}.log"
#     shell:
#         """
#         clusterfunk prune \
#           --extract \
#           --trait uk_lineage \
#           --input {input.tree} \
#           --output {output.outdir} &> {log}
#         """
#
# rule output_annotations:
#     input:
#         tree = rules.label_introductions.output.tree
#     params:
#         lineage = config["lineage"]
#     output:
#         traits = config["output_path"] + "/4/{params.lineage}/trees/traits.csv"
#         completed = config["output_path"] + "/4/summary.txt"
#     log:
#         config["output_path"] + "/logs/4_output_annotations_{params.lineage}.log"
#     shell:
#         """
#         clusterfunk extract_annotations \
#           --traits country lineage uk_lineage acc_lineage \
#           --input {input.tree} \
#           --output {output.traits} &> {log}
#
#         echo "Lineage {params.lineage} complete" >> {output.completed}
#         """
#
