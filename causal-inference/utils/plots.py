#=====================================================================================
# scientific plotting style setting
#=====================================================================================
def set_plot_style(science_plots=False):

    import matplotlib.pyplot as plt
    import scienceplots

    if science_plots:

        plt.style.use(['science', 'notebook'])

    else:
        plt.style.use(['default'])
        
    plt.rcParams.update({ 
        "text.usetex": True,
        "font.family": "Times New Roman",
        "font.size": 12
    })