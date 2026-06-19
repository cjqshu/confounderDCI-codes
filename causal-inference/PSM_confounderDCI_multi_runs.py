import numpy as np
import pandas as pd

from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

from utils.metrics import sqrt_PEHE, ATE_error
from utils.set_seed import set_random_seed

SEED = 42
set_random_seed(seed=SEED)

from sklearn.linear_model import LogisticRegression, Ridge
from sklearn.neighbors import NearestNeighbors

def fit_propensity(X_arr: np.ndarray, d: np.ndarray, EPS: float) -> np.ndarray:
    m = LogisticRegression(max_iter=5000, solver="lbfgs", random_state=SEED)
    m.fit(X_arr, d)
    e = m.predict_proba(X_arr)[:, 1]
    return np.clip(e, EPS, 1.0 - EPS)

def fuse_propensity_linear(e_conf: np.ndarray, e_non: np.ndarray, w_conf: float, EPS: float) -> np.ndarray:
    w = float(np.clip(w_conf, 0.0, 1.0))
    e = w * e_conf + (1.0 - w) * e_non
    return np.clip(e, EPS, 1.0 - EPS)

def propensity_matching_ite(
    X_arr: np.ndarray, y_arr: np.ndarray, d: np.ndarray, e: np.ndarray, k: int = 3
) -> tuple:

    if k < 1:
        raise ValueError("k must be >= 1")
    e1 = e.reshape(-1, 1)
    idx_t = np.where(d == 1)[0]
    idx_c = np.where(d == 0)[0]
    k_c = min(k, len(idx_c))
    k_t = min(k, len(idx_t))
    y1_hat = np.zeros_like(y_arr, dtype=float)
    y0_hat = np.zeros_like(y_arr, dtype=float)

    if len(idx_t) > 0:
        nn_t_obs = NearestNeighbors(n_neighbors=min(k_t, len(idx_t)))  
        nn_t_obs.fit(e1[idx_t])
        knn_idx_t_obs = nn_t_obs.kneighbors(e1[idx_t], return_distance=False)[:, 0:] 
        y1_obs_hat = y_arr[idx_t][knn_idx_t_obs].mean(axis=1) if k_t > 1 else y_arr[idx_t][knn_idx_t_obs[:,0]]
        nn_c = NearestNeighbors(n_neighbors=k_c)
        nn_c.fit(e1[idx_c])
        matched_c_for_t = idx_c[nn_c.kneighbors(e1[idx_t], return_distance=False)]
        y0_cf_hat = y_arr[matched_c_for_t].mean(axis=1)
        y1_hat[idx_t] = y1_obs_hat
        y0_hat[idx_t] = y0_cf_hat

    if len(idx_c) > 0:
        nn_c_obs = NearestNeighbors(n_neighbors=min(k_c, len(idx_c)))
        nn_c_obs.fit(e1[idx_c])
        knn_idx_c_obs = nn_c_obs.kneighbors(e1[idx_c], return_distance=False)[:, 0:]
        y0_obs_hat = y_arr[idx_c][knn_idx_c_obs].mean(axis=1) if k_c > 1 else y_arr[idx_c][knn_idx_c_obs[:,0]]
        nn_t = NearestNeighbors(n_neighbors=k_t)
        nn_t.fit(e1[idx_t])
        matched_t_for_c = idx_t[nn_t.kneighbors(e1[idx_c], return_distance=False)]
        y1_cf_hat = y_arr[matched_t_for_c].mean(axis=1)
        y0_hat[idx_c] = y0_obs_hat
        y1_hat[idx_c] = y1_cf_hat

    ite_hat = y1_hat - y0_hat

    return y1_hat, y0_hat, ite_hat


if __name__ == "__main__":

    EPS = 1e-1
    MATCH_K = 9
    OMEGA_CONF = 0.7 

    confounder_dict_CDs = {

        "ConfounderDCI": [9, 3]
    }

    file_idx_list = [0, 2, 3, 6, 7]

    summary_results = []

    for conf_key, confounder_ids in confounder_dict_CDs.items():
        pehe_pm_lst = []
        ate_err_pm_lst = []
        ate_hat_lst = []

        for file_idx in file_idx_list:  
            file_path = f"datasets/IHDP/ihdp_npci_with_names_{file_idx}.csv"
            df = pd.read_csv(file_path)

            feature_cols = [c for c in df.columns if c.startswith("x")]
            X = df[feature_cols].to_numpy(dtype=float)
            t = df["treatment"].to_numpy(dtype=int)
            y_factual = df["y_factual"].to_numpy(dtype=float)
            y_cfactual = df['y_cfactual'].to_numpy(dtype=float)
            ITE_true = df["mu1"] - df["mu0"]
            ATE_true = float(np.mean(ITE_true))

            IDX_CONFOUND = [i-1 for i in confounder_ids]
            IDX_NONCONFOUND = [i for i in range(X.shape[1]) if i not in IDX_CONFOUND]

            X_c = X[:, IDX_CONFOUND]
            X_nc = X[:, IDX_NONCONFOUND]
            e_conf = fit_propensity(X_c, t, EPS)
            e_non = fit_propensity(X_nc, t, EPS)
            e_fuse_lin = fuse_propensity_linear(e_conf, e_non, OMEGA_CONF, EPS)

            y1_hat_pm, y0_hat_pm, ite_hat_pm = propensity_matching_ite(
                X_arr=X, y_arr=y_factual, d=t, e=e_fuse_lin, k=MATCH_K
            )

            Y_true = np.stack([df["mu0"].to_numpy(float), df["mu1"].to_numpy(float)], axis=1)
            Y_hat_pm = np.stack([y0_hat_pm, y1_hat_pm], axis=1)

            pehe_pm, _ = sqrt_PEHE(Y_true, Y_hat_pm)
            ate_err_pm, _ = ATE_error(Y_true, Y_hat_pm)
            ate_hat = float(np.mean(ite_hat_pm))

            pehe_pm_lst.append(pehe_pm)
            ate_err_pm_lst.append(ate_err_pm)
            ate_hat_lst.append(ate_hat)

        pehe_pm_mean = np.mean(pehe_pm_lst)
        pehe_pm_std = np.std(pehe_pm_lst, ddof=1)
        ate_err_pm_mean = np.mean(ate_err_pm_lst)
        ate_err_pm_std = np.std(ate_err_pm_lst, ddof=1)
        ate_hat_mean = np.mean(ate_hat_lst)
        ate_hat_std = np.std(ate_hat_lst, ddof=1)

        summary_results.append({
            "Method": conf_key,
            "PEHE": f"{pehe_pm_mean:.3f}±{pehe_pm_std:.3f}",
            "ATE_error": f"{ate_err_pm_mean:.3f}±{ate_err_pm_std:.3f}",
            "ATE_hat": f"{ate_hat_mean:.3f}±{ate_hat_std:.3f}",
        })

    result_dataset_ID = pd.DataFrame({"Method": conf_key, "PEHE": pehe_pm_lst, "ATE_error": ate_err_pm_lst, "ATE_hat": ate_hat_lst})
    print(result_dataset_ID)

    print(100*"-")

    df_result = pd.DataFrame(summary_results).sort_values("PEHE")
    print(df_result)

    result_dataset_ID.to_csv("results/IHDP/PSM_confounderDCI_multi_runs_IHDP_dataset_ID.csv", index=False)
