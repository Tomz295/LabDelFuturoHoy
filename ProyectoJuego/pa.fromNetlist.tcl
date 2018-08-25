
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name ProyectoJuego -dir "C:/Users/Invitado/Desktop/Super Lab Del Futuro Hoy/ProyectoJuego/planAhead_run_3" -part xc3s500efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Invitado/Desktop/Super Lab Del Futuro Hoy/ProyectoJuego/MainGame.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Invitado/Desktop/Super Lab Del Futuro Hoy/ProyectoJuego} }
set_property target_constrs_file "MainUCF.ucf" [current_fileset -constrset]
add_files [list {MainUCF.ucf}] -fileset [get_property constrset [current_run]]
open_netlist_design
