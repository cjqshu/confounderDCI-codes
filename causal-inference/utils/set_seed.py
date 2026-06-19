
#=====================================================================================
# 设置随机种子
#=====================================================================================
def set_random_seed(seed=0):

    import os
    import pandas as pd
    import numpy as np
    import random
    import torch    

    os.environ["PYTHONHASHSEED"] = str(seed)
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.benchmark = False
    torch.backends.cudnn.deterministic = True
    # torch.set_default_dtype(torch.float32)