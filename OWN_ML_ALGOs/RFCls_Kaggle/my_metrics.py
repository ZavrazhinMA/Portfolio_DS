import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def metrics(y_true, y_pred, metric='f1_score', f1_beta=1):
    TP = np.sum(np.logical_and(y_pred == 1, y_true == 1))
    FP = np.sum(np.logical_and(y_pred == 1, y_true == 0))
    FN = np.sum(np.logical_and(y_pred == 0, y_true == 1))
    TN = np.sum(np.logical_and(y_pred == 0, y_true == 0))
    precision = TP / (TP + FP)
    recall = TP / (TP + FN)

    if metric == 'accuracy':
        accuracy = (TP + TN) / y_true.shape[0]
        return round(accuracy, 4)

    if metric == 'precision_recall':
        return round(precision, 4), round(recall, 4)

    if metric == 'f1_score':
        f1_score = (1 + f1_beta ** 2) * (precision * recall) / (f1_beta * precision + recall)
        return round(f1_score, 4)

    if metric == 'matrix':
        return {'TP': TP, 'FP': FP, 'FN': FN, 'TN': TN}

    if metric == 'accuracy_balanced':
        accuracy_balanced = 0.5 * (TP / (TP + FN) + TN / (TN + FP))
        return round(accuracy_balanced, 4)


def get_proba_data(y_true, y_proba):
    proba_data = pd.DataFrame(
        {'proba': y_proba, 'y_true': y_true})
    proba_data = proba_data.sort_values(
        by='proba', ascending=False).reset_index(drop=True)
    return proba_data


def roc_auc(y_true, y_proba):
    proba_data = get_proba_data(y_true, y_proba)
    N = len(y_true)
    n_pos = np.count_nonzero(y_true)
    n_neg = N - n_pos
    TP = 0
    FP = 0
    TPR = [0]
    FPR = [0]
    for i in range(N):
        if proba_data.iloc[i, 1] == 1:
            TP += 1
        else:
            FP += 1
        TPR.append(TP / n_pos)
        FPR.append(FP / n_neg)
    ROC_AUC = np.trapz(TPR, x=FPR, dx=0.1)

    plt.figure(figsize=(12, 8))
    plt.plot(FPR, TPR, color='b', linewidth=2,
             label=f'ROC curve\nROC_AUC = {round(ROC_AUC, 3)}')
    plt.plot((0, 1), (0, 1), color='dimgray',
             linewidth=1, linestyle='dashed')
    plt.xlabel('FPR')
    plt.ylabel('TPR')
    plt.fill_between(FPR, TPR, alpha=0.5, color='lightblue')
    if N <= 100:
        plt.scatter(FPR, TPR, edgecolors='white', s=55, c='dimgray')
    plt.legend(loc='best', facecolor='white', shadow=True, fontsize=15)
    plt.show()


def pr_auc(y_true, y_proba):

    proba_data = get_proba_data(y_true, y_proba)
    N = len(y_true)
    n_pos = np.count_nonzero(y_true)
    TP = 0
    FP = 0
    recall = [0]
    precision = [0]

    for i in range(N):
        if proba_data.iloc[i, 1] == 1:
            TP += 1
        else:
            FP += 1
        recall.append(TP / n_pos)
        precision.append(TP / (TP + FP))
    PR_AUC = np.trapz(precision, x=recall, dx=0.1)

    plt.figure(figsize=(12, 8))
    plt.plot(recall, precision, color='b', linewidth=2,
             label=f'PR curve\nPR_AUC = {round(PR_AUC, 3)}')
    plt.xlabel('recall')
    plt.ylabel('precision')
    plt.fill_between(recall, precision, alpha=0.5, color='lightblue')
    if N <= 100:
        plt.scatter(recall, precision, edgecolors='white', s=55, c='dimgray')
    plt.legend(loc='best', facecolor='white', shadow=True, fontsize=15)
    plt.show()


def get_full_report(y_true, y_pred, y_proba, title=None, metric=None, auc=False):
    if metric is None:
        metric = ['accuracy', 'f1_score', 'precision_recall']
    for metr in metric:
        print(f'{title}. Метрика {metr} = {metrics(y_true, y_pred, metric=metr)}')
    print()
    print('=' * 100)
    if auc:
        roc_auc(y_true, y_proba)
        pr_auc(y_true, y_proba)
